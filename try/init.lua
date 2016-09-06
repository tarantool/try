-- This script for start and work try.tarantool.org.
-- Try.tarantool is web pages with terminal that user can use
-- tarantool console and try tarantool uses cases.


local io = require('io')
local os = require('os')
local json = require('json')
local math = require('math')
local digest = require('digest')
local log = require('log')
local fiber = require('fiber')
local client = require('http.client')
local server = require('http.server')
local socket = require('socket')

local APP_DIR = '/usr/share/tarantool/try'
local CONTAINER_PORT = '3313'

local DOCKER ='http://unix/:/var/run/docker.sock:'
local DOCKER_IMAGE='tarantool/try:latest'
local IP_LIMIT = 10
local SOCKET_TIMEOUT = 3
local TIME_DIFF = 1800
local CLEANING_PERIOD = 3600
local SERVER_ERROR = 'Sorry! The server has a problem. Please update the web page.'
local SOCKET_ERROR = 'Sorry! The server has a problem with socket. Please update the web page.'
local COOKIE_ERROR = 'Sorry! Your cookie does not match your ip adress. Please clear cookies and update the web page.'
local LIMIT_ERROR = 'Sorry! The limit on active users has been exceeded! Please try again later.'
local COMMAND_ERROR = 'Sorry! Command is null. You must send a command in the request.'
local EXIT_ERROR = 'Attention! The server has stopped your tarantool machine. Please wait for restart or update the web page.'
local CONTAINER_PRELUDE=
     "require('console').delimiter('!!')"..
     "require('console').delimiter=function() "..
     "return('Please use shift+enter on try.tarantool.org')"..
     "end\n"

-- Table with information about users try.tarantool session on ip
local ipt = {}
-- Table with information about user: id, ip, linux container host and id,
-- last connection time
local lxc = {}

local function docker(method, uri, body)
    if body then
        body = json.encode(body)
    end
    local headers = { ["Content-Type"] = "application/json" }
    local r = client.request(method, DOCKER..uri, body, { headers = headers })
    if r.status < 200 or r.status >= 300 then
        log.error('failed to process docker request: %s %s %s', uri, r.status,
            r.body)
        return
    end
    log.debug('docker: %s %s [[%s]] => %s [[%s]]', method, uri, body or '',
    r.status, r.body)
    if #r.body == 0 then
        return true
    end
    return json.decode(r.body)
end

-- Function send request to docker for killing container

local function rm_lxc(lxc_id)
    local inf1 = docker('POST', '/containers/'..lxc_id..'/kill')
    if not inf1 then
        return
    end
    local inf2 = docker('DELETE', '/containers/'..lxc_id)
    if not inf2 then
        return
    end
    log.info('removed container %s', lxc_id)
end

--Fuction remove old linux container

local function remove_old_containers()
    log.info('begin removing old containers')
    local inf = docker('GET', '/containers/json?all=1')
    if not inf then
        return
    end
    for _, i in ipairs(inf) do
        if string.find(i.Command, 'container.lua', nil, true) then
            rm_lxc(i.Id)
        end
    end
    log.info('finish removing old containers')
end

-- Function start container

local function remove_container(user_id)
    local user_info = lxc[user_id]
    rm_lxc(user_info.lxc_id)
    ipt[user_info.ip] = ipt[user_info.ip] - 1
    lxc[user_id] = nil
end

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
    lxc[user_id].lxc_id = lxc_id

    -- Start container
    local inf = docker('POST', '/containers/'..lxc_id..'/start')
    if not inf then
        log.error('failed to start container')
        remove_container(user_id)
        return false
    end

    -- Get container information
    local inf = docker('GET', '/containers/'..lxc_id..'/json')
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
        log.debug('connecting to %s:%s', lxc[user_id].host, CONTAINER_PORT)
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
        log.debug('Started remove unused container')
        t = os.time()
        for k,v in pairs(lxc) do
            if (t - v.time) >= TIME_DIFF then
                remove_container(k)
            end
        end
        log.debug('Stopped remove unused conainer')
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

-- Handler for request from try.tarantool page
local function handler (self)
    local user_ip = self.headers['x-real-ip'] or
        self.headers['x-forwarded-for'] or self.peer.host
    local user_id = self:cookie('id')  -- Get cookie with id information
    if user_id == nil then -- Set cookie with id for new users
        user_id = user_ip..'//'..tostring(math.random(0, 65000))
    end

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
