-- This script for start and work try.tarantool.org.
-- Try.tarantool is web pages with terminal that user can use
-- tarantool console and try tarantool uses cases.


local fio    = require('fio')
local log    = require('log')
local json   = require('json')
local math   = require('math')
local fiber  = require('fiber')
local httpc  = require('http.client')
local digest = require('digest')
local socket = require('socket')

local server = require('http.server')

local APP_DIR = debug.getinfo(1).source:match("@?(.*/)") or '.'
local CONTAINER_PORT = '3313'  

local DOCKER ='http://127.0.0.1:12345'
local DOCKER_IMAGE='tarantool/try:latest'
local IP_LIMIT = 10
local SOCKET_TIMEOUT = 3
local TIME_DIFF = 1800
local CLEANING_PERIOD = 3600
local SERVER_ERROR  = 'Sorry! The server has a problem. Please update the we' ..
                      'b page.'
local SOCKET_ERROR  = 'Sorry! The server has a problem with socket. Please u' ..
                      'pdate the web page.'
local COOKIE_ERROR  = 'Sorry! Your cookie does not match your ip adress. Ple' ..
                      'ase clear cookies and update the web page.'
local LIMIT_ERROR   = 'Sorry! The limit on active users has been exceeded! P' ..
                      'lease try again later.'
local COMMAND_ERROR = 'Sorry! Command is null. You must send a command in th' ..
                      'e request.'
local EXIT_ERROR    = 'Attention! The server has stopped your tarantool mach' ..
                      'ine. Please wait for restart or update the web page.'
local CONTAINER_PRELUDE = "require('console').delimiter('!!')"                      ..
                          "require('console').delimiter = function() "              ..
                          "  return('Please use shift+enter on try.tarantool.org')" ..
                          "end\n"

-- Table with information about users try.tarantool session on ip
local ipt = {}

-- Table with information about user:
-- id, ip, linux container host and id, last connection time
local lxc = {}

local function docker(method, uri, body, ...)
    if body then
        body = json.encode(body)
    end
    if select('#', ...) > 0 then
        uri = uri:format(...)
    end
    uri = DOCKER .. uri
    local headers = { ["Content-Type"] = "application/json" }
    log.verbose('sending %s request to %s', method, uri)
    local response = httpc.request(method, uri, body, {
        headers = headers,
        timeout = 10
    })
    log.verbose('response: %s', json.encode(response))
    if response.status < 200 or response.status >= 300 then
        log.error('failed to process docker request for %s with status %s: %s',
                   uri, response.status, response.body)
        return
    end
    log.verbose('docker: %s %s [[%s]] => %s [[%s]]', method, uri, body or '',
                 response.status, response.body)
    if not response.body or #response.body == 0 then
        return true
    end
    return json.decode(response.body)
end

-- Function send request to docker for killing container
local function rm_lxc(lxc_id)
    if lxc_id == nil then
        log.info('Failed to remove container: id is nil')
        return nil
    end
    local inf1 = docker('POST', '/containers/%s/kill', nil, lxc_id)
    if not inf1 then
        return
    end
    local inf2 = docker('DELETE', '/containers/%s', nil, lxc_id)
    if not inf2 then
        return
    end
    log.info('removed container %s', lxc_id)
end

local function remove_container(user_id)
    local user_info = lxc[user_id]
    rm_lxc(user_info.lxc_id)
    ipt[user_info.ip] = ipt[user_info.ip] - 1
    lxc[user_id] = nil
end

-- Function remove old linux container
local function remove_old_containers()
    log.info('begin removing old containers')
    local inf = docker('GET', '/containers/json?all=1')
    if not inf then
        return
    end
    for _, i in ipairs(inf) do
        log.info("container: %s", json.encode(inf))
        if i.Command:find('container.lua', nil, true) then
            rm_lxc(i.Id)
        end
    end
    log.info('finish removing old containers')
end

-- Function start container
local function start_container(user_id, user_ip)
    lxc[user_id] = { ip = user_ip, time = os.time() }
    ipt[user_ip] = ipt[user_ip] + 1

    local body = {
        Image = DOCKER_IMAGE;
        HostConfig = {
            Memory = 536870912;
            MemorySwap = 0;
            CpuShares =  2;
        }
    }

    --  Create container
    local inf = docker('POST', '/containers/create', body)
    if not inf or not inf.Id then
        ipt[user_ip] = ipt[user_ip] - 1
        lxc[user_id] = nil
        log.error('failed to create container')
        return false
    end

    local lxc_id = inf.Id
    if lxc_id == nil then
        log.error("failed to start container: lxc_id is nil [%s]",
                   json.encode(inf))
    end
    lxc[user_id].lxc_id = lxc_id

    -- Start container
    local inf = docker('POST', '/containers/%s/start', nil, lxc_id)
    if not inf then
        log.error('failed to start container')
        remove_container(user_id)
        return false
    end

    -- Get container information
    local inf = docker('GET', '/containers/%s/json', nil, lxc_id)
    if not inf or not inf.NetworkSettings or
       not inf.NetworkSettings.IPAddress then
        log.error('failed to get information about container')
        remove_container(user_id)
        return false
    end
    local host = inf.NetworkSettings.IPAddress
    log.info('started container %s with ip = %s', lxc_id, host)
    lxc[user_id].host = host

    -- Connect to container
    for i = 0, 20 do -- Start new socket connection
        -- log.verbose('connecting to %s:%s', lxc[user_id].host, CONTAINER_PORT)
        -- log.verbose('connecting to %s:%s', lxc[user_id].host, CONTAINER_PORT)
        local s = socket.tcp_connect(host, CONTAINER_PORT)
        if s then
            -- Add delimiter for multiline commands
            if s:write(CONTAINER_PRELUDE) and s:read('\n...\n', 1) then
               lxc[user_id].socket = s
               return true
            end
            s:close()
        end
        fiber.sleep(SOCKET_TIMEOUT)
    end
    log.error('failed to connect container %s with ip %s', lxc_id, host)
    remove_container(user_id)
    return false
end

-- Function remove container
-- Function remove all container that not used

local function clear_lxc()
    while 1 do
        log.verbose('Started remove unused container')
        local t = os.time()
        for k, v in pairs(lxc) do
            if (t - v.time) >= TIME_DIFF then
                log.verbose('Removing container %s', k)
                remove_container(k)
            end
        end
        log.verbose('Stopped remove unused conainer')
        fiber.sleep(CLEANING_PERIOD)
    end
end

-- Function sends error messanges

local function send_error(self, data, user_id)
    if not data then
        local data = SERVER_ERROR
    end
    if user_id then remove_container(user_id) end
    return self:render({ text = data })
end

local user_id_fmt = '%s//%s'

-- Handler for request from try.tarantool page
local function handler (self)
    local user_ip = self.headers['x-real-ip'] or
                    self.headers['x-forwarded-for'] or
                    self.peer.host
    -- Get cookie with id information OR set cookie with id for new users
    local user_id = self:cookie('id') or user_id_fmt:format(user_ip,
             tostring(math.random(0, 65000)))

    if not ipt[user_ip] then ipt[user_ip] = 0 end

    if not lxc[user_id] then
        -- Check limit (5 users) for one ip adress
        if ipt[user_ip] >= IP_LIMIT then
            return send_error(self, LIMIT_ERROR)
        end
        -- Start new container for user
        if not start_container(user_id, user_ip) then
            return send_error(self, SERVER_ERROR)
        end
   else
        -- Check that cookies match ip adress
        if not user_ip == lxc[user_id].ip then
            return send_error(self, COOKIE_ERROR)
        end
        for i = 0, 10 do
            if lxc[user_id].socket then break end
            fiber.sleep(SOCKET_TIMEOUT)
        end
        if not lxc[user_id].socket then
            return send_error(self, SOCKET_ERROR, user_id)
        end
    end
    -- Send message to tarantool in container and get answer
    local command = self:query_param('command')
    if not command then
        log.error("command to server is nil")
        return send_error(self, COMMAND_ERROR , user_id)
    end
    log.info('command: <%s>', command)
    if not lxc[user_id].socket:write(command..'!!\n') then
        log.error("failed to write command")
        return send_error(self, SERVER_ERROR, user_id)
    end
    local data = lxc[user_id].socket:read('\n...\n', 1)
    if (not data) or (data == '') then
        log.error("failed to read response")
        return send_error(self, EXIT_ERROR, user_id)
    end
    -- Write time last socket connection
    lxc[user_id]['time'] = os.time()
    log.info('answer:\n%s', data)
    return self:render({ text = data }):
        setcookie({ name = 'id', value = user_id, expires = '+1y' })
end

-- Start tarantool server

local function start(host, port)
    if host == nil or port == nil then
        error('Usage: start(host, port)')
    end

    -- while next(fio.glob('/var/run/docker.sock')) == nil do
    --    fiber.sleep(0.5)
    --end
    fiber.sleep(5)

    os.execute('docker build -t tarantool/try ' .. APP_DIR .. '/container')
    -- prevent access from containers to outside world
    os.execute('/bin/sh -c "echo 0 > /proc/sys/net/ipv4/ip_forward"')

    httpd = server.new(host, port, {app_dir = APP_DIR})
    log.info('Started http server at host = %s and port = %s ', host, port)
    -- Start fiber for remove unused containers
    clear = fiber.create(clear_lxc)
    httpd:start()
    remove_old_containers()
    httpd:stop()
    httpd:route({ path = '/blank', file = '/blank.html'})
    httpd:route({ path = '', file = '/index.html'})
    httpd:route({ path = '/tarantool' }, handler)
    httpd:start()
end

return {
    start = start
}
