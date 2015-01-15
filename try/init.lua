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

local APP_DIR = './try'
local CONTAINER_PORT = '3313'
local DOCKER ='http://unix/:/var/run/docker.sock:'
local IP_LIMIT = 5
local SOCKET_TIMEOUT = 0.5
local TIME_DIFF = 1800
local CLEANING_PERIOD = 3600
local SERVER_ERROR = 'Sorry! Server have problem.Please update web page.'
local SOCKET_ERROR = 'Sorry! Server have problem with socket. Please update web page.'
local COOKIE_ERROR = 'Sorry! Cookies do not match ip adress. Please, clear cookies and update web page.'
local LIMIT_ERROR = 'Sorry! Users limit exceeded! Please, close some session.'
local EXIT_ERROR = 'Attention! Server stopped your tarantool machine. Please, wait for restart or update web page.'

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

local function start_container(user_id)
    local body = {
            Memory = "512m";
            MemorySwap = 0;
            CpuShares =  1;
            Image = "tarantool";
    }

    --  Create container
    local inf = docker('POST', '/containers/create', body)
    if not inf or not inf.Id then
        log.error('failed to create container')
        return false
    end
    local lxc_id = inf.Id
 
    -- Start container    
    local inf = docker('POST', '/containers/'..lxc_id..'/start',
	{ Detach = true })
    if not inf then
        log.error('failed to start container')
        return false
    end
 
    -- Get container information
    local inf = docker('GET', '/containers/'..lxc_id..'/json')
    if not inf or not inf.NetworkSettings or
       not inf.NetworkSettings.IPAddress then
        log.error('failed to get information about container')
        return false
    end
    local host = inf.NetworkSettings.IPAddress
    log.info('%s: started container %s with ip = %s', user_id, lxc_id, host)
    lxc[user_id] = { host = host, lxc_id = lxc_id }
    return true
end

-- Function remove container

local function remove_container(user_id)
    local lxc_id = lxc[user_id].lxc_id
    rm_lxc(lxc_id)
    ipt[lxc[user_id].ip] = ipt[lxc[user_id].ip] - 1
    lxc[user_id] = nil
end

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

function handler (self)
    local user_ip = nil

    user_ip = self.peer.host

    local host = nil
    local lxc_id = nil
    local t ={}
    local data = nil

    if not ipt[user_ip] then ipt[user_ip] = 0 end

    local user_id = self:cookie('id')  -- Get cookie with id information
    if user_id == nil then -- Set cookie with id for new users
        user_id = user_ip..'//'..tostring(math.random(0, 65000))
    end

    if not lxc[user_id] then
        -- Check limit (5 users) for one ip adress
        if ipt[user_ip] >= IP_LIMIT then
            return send_error(self, LIMIT_ERROR)
        end
        ipt[user_ip] = ipt[user_ip] + 1
        -- Start new container for user
        if not start_container(user_id) then
            return send_error(self, SERVER_ERROR)
        end
        lxc[user_id]['ip'] = user_ip

        for i = 0, 20 do -- Start new socket connection
                lxc[user_id].socket = socket.tcp_connect(lxc[user_id].host,
                                                         CONTAINER_PORT)
                log.debug('%s: connecting to %s:%s', user_id, 
                         lxc[user_id].host, CONTAINER_PORT)
                if lxc[user_id].socket then 
                    -- Add delimiter for multiline commands
                    lxc[user_id].socket: write("require('console').delimiter('!!')\n") 
                    local inf = lxc[user_id].socket:read('\n%.%.%.\n', 1)
                    lxc[user_id].socket: write(
                       "require('console').delimiter=function()return('Please use shift+enter on try.tarantool.org') end!!\n") 
                    inf = lxc[user_id].socket:read('\n%.%.%.\n', 1)
                    break
                end
                fiber.sleep(SOCKET_TIMEOUT)
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
        -- User get container from container table(lxc[])$
        log.debug('%s: User got container with host = %s', user_id, 
                  lxc[user_id].host)
    end
    -- Check that socket connection have
    if lxc[user_id].socket then
        -- Send message to tarantool in container and get answer
        local command = self:query_param('command')
        log.info('%s: command <%s>', user_id, command)
        if lxc[user_id].socket: write(command..'!!\n') then
            data = lxc[user_id].socket:read('\n%.%.%.\n', 1)
            if (not data) or (data == '') then
                return send_error(self, EXIT_ERROR, user_id)
            end
        else
            return send_error(self, SERVER_ERROR, user_id)
        end
        -- Write time last socket connection
        lxc[user_id]['time'] = os.time()
        log.info('%s: answer:\n %s', user_id, data)
        return self:render({ text = data }):
            setcookie({ name = 'id', value = user_id, expires = '+1y' })
    else
        log.info('%s: failed to connect', user_id)
        return send_error(self, SOCKET_ERROR, user_id)
    end
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
    httpd:route({ path = '', file = '/index.html'})
    httpd:route({ path = '/tarantool' }, handler)
    httpd:start()
    -- Random init
    math.randomseed(tonumber(require('fiber').time64()))
end

return {
start = start
}
