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
local server = require('http.server')
local socket = require('socket')

local SERVER_HOST = '0.0.0.0'
local SERVER_PORT = '22222'
local CONTAINER_PORT = '3313'
local IP_LIMIT = 10
local SOCKET_TIMEOUT = 0.2
local START_LXC = 'sudo /usr/local/try-tarantool-org/container/tool.sh start '
local RM_LXC = 'sudo /usr/local/try-tarantool-org/container/tool.sh stop '
local TIME_DIFF = 1800
local CLEANING_PERIOD = 3600
local SERVER_ERROR = 'Sorry! Server have problem. Please update web page.'
local SOCKET_ERROR = 'Sorry! Server have problem with socket. Please update web page.'
local COOKIE_ERROR = 'Sorry! Cookies do not match ip adress. Please, clear cookies and update web page.'
local LIMIT_ERROR = 'Sorry! Users limit exceeded! Please, close some session.'
local EXIT_ERROR = 'Attention! Server stopped your tarantool machine. Please, wait for restart or update web page.'

local ipt = {} -- Table with information about users try.tarantool session on ip
local lxc = {} -- Table with information about user: id, ip, linux container host and id, last connection time
local tfun = {} -- Table for start module function and redefine some function or value

tfun['ipt'] = ipt -- For revoke limit count in try test

-- Function start container

local function start_container(user_id)
    local file = io.popen(START_LXC)
    local inf = file:read("*a")
    file:close()
    inf = json.decode(inf)
    local host = inf[1]['NetworkSettings']['IPAddress']
    local lxc_id = inf[1]['ID']
    log.info('%s: Start container with host = %s lxc_id = %s ', user_id, host, lxc_id)
    return host, lxc_id
end

-- Function remove container

local function remove_container(user_id)
    local lxc_id = lxc[user_id].lxc_id
    log.info(RM_LXC..lxc_id)
    local file = io.popen(RM_LXC..lxc_id)
    file:close()
    log.info('%s: Remove container with ID = %s', user_id, lxc_id)
    tfun.ipt[lxc[user_id].ip] = tfun.ipt[lxc[user_id].ip] - 1
end

tfun['SERVER_PORT'] = SERVER_PORT
tfun['CONTAINER_PORT'] = CONTAINER_PORT
tfun['start_container'] = start_container
tfun['remove_container'] = remove_container

-- Function remove all container that not used

local function clear_lxc()
    while 1 do
        log.debug('Started remove unused container')
        t = os.time()
        for k,v in pairs(lxc) do
            if (t - v.time) >= TIME_DIFF then
                tfun.remove_container(k)
                tfun.ipt[v.ip] = tfun.ipt[v.ip] - 1
                lxc[k] = nil
            end
        end
        log.debug('Stopped remove unused conainer')
        fiber.sleep(CLEANING_PERIOD)
    end
end

tfun['clear_lxc'] = clear_lxc

-- Function sends error messanges

local function send_error(self, data, user_id)
    if not data then
        local data = SERVER_ERROR
    end
    if user_id then
         tfun.remove_container(user_id)
         tfun.ipt[lxc[user_id].ip] = tfun.ipt[lxc[user_id].ip] - 1
         lxc[user_id] = nil
    end
    return self:render({ text = data })
end

-- Handler for request from try.tarantool page

function handler (self)
    local user_ip = nil

    user_ip = self.req.peer.host

    local host = nil
    local lxc_id = nil
    local t ={}
    local data = nil

    if not tfun.ipt[user_ip] then tfun.ipt[user_ip] = 0 end

    local user_id = self:cookie('id')  -- Get cookie with id information

    if user_id == nil then -- Set cookie with id for new users
        log.info ('Set cookie for ip = %s', user_ip)
        user_id = user_ip..'//'..tostring(math.random(0, 65000))
        self:cookie({ name = 'id', value = user_id, expires = '+1y' })
    end

    if not lxc[user_id] then
        -- Check limit (5 users) for one ip adress
        if tfun.ipt[user_ip] >= IP_LIMIT then
            return send_error(self, LIMIT_ERROR)
        end
        tfun.ipt[user_ip] = tfun.ipt[user_ip] + 1
        log.info('Have %s session on this ip = %s', tfun.ipt[user_ip], user_ip)
        -- Start new container for user
        host, lxc_id = tfun.start_container(user_id)
        lxc[user_id] = { host = host, lxc_id = lxc_id }
        log.info('%s: User got new container with host = %s', user_id, lxc[user_id].host)
        lxc[user_id]['ip'] = user_ip

        for i = 0, 10 do -- Start new socket connection
                lxc[user_id].socket = socket.tcp_connect(lxc[user_id].host, tfun.CONTAINER_PORT)
                log.info('%s: Started socket on host %s port %s', user_id, lxc[user_id].host, tfun.CONTAINER_PORT)
                if lxc[user_id].socket then break end
                fiber.sleep(SOCKET_TIMEOUT)
        end
    else
        -- Check that cookies match ip adress
        if not user_ip == lxc[user_id].ip then
            send_error(self, COOKIE_ERROR)
        end
        for i = 0, 10 do
            if lxc[user_id].socket then break end
            fiber.sleep(SOCKET_TIMEOUT)
        end
        -- User get container from container table(lxc[])$
        log.debug('%s: User got container with host = %s', user_id, lxc[user_id].host)
    end
    -- Check that socket connection have
    if lxc[user_id].socket then
        -- Send message to tarantool in container and get answer
        log.debug('%s: Started and get answer', user_id)
        local command = self.req:param('command')
        log.info('%s: Getting command <%s>', user_id, command)
        if lxc[user_id].socket: write(command..'\n') then
            log.debug('%s: Socket read', user_id)
            data = lxc[user_id].socket:read('\n%.%.%.\n', 1)
            if (not data) or (data == '') then
                send_error(self, EXIT_ERROR, user_id)
                return
            end
        else
            send_error(self, SERVER_ERROR, user_id)
        end
        -- Write time last socket connection
        lxc[user_id]['time'] = os.time()
        log.info('%s: Had answer:\n %s', user_id, data)
        return self:render({ text = data })
    else
        log.info('%s: Hasnt socket conection', user_id)
        return send_error(self, SOCKET_ERROR, user_id)
    end
end

-- Start tarantool server

local function start()
    httpd = server.new(SERVER_HOST, SERVER_PORT, {app_dir = '.'})
    log.info('Started http server at host = %s and port = %s ', SERVER_HOST, SERVER_PORT)
    -- Start fiber for remove unused containers
    clear = fiber.create(tfun.clear_lxc)

    httpd:route({ path = '', file = '/index.html'})
    httpd:route({ path = '/tarantool' }, handler)
    httpd:start()
    -- Random init
    math.randomseed(tonumber(require('fiber').time64()))
end

tfun['start'] = start
return tfun
