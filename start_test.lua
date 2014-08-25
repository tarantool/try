#!usr/bin/env tarantool
-- This is script for start testing try.tarantool
local log = require('log')
local client = require('http.client')
local yaml = require('yaml')
local fiber = require('fiber')

local CONSOLE_PORT = '33014'

box.cfg{
    log_level = 5,
}

local try = require('tmp_try')

require('console').listen('127.0.0.1:'..CONSOLE_PORT)

log.info('Start try.tarantool tests')
try.CONTAINER_PORT = '33001'
try.start_container = function() return '127.0.0.1', CONSOLE_PORT end
try.remove_container = function() log.info('Test remove done') end
try.clear_lxc = function() log.info('Test lsc clear done') fiber.sleep(1800) end

try.start()

-- Test cases

-- Check socket error 
try.CONTAINER_PORT = '33001'
log.info(yaml.encode(client.request('GET', 'http://localhost:22222/tarantool?command=help', nil, {headers = {cookie = 'id='..1}}).body))

try.CONTAINER_PORT = CONSOLE_PORT

--Check requests for one user (one cookie) 
for i = 1, 5, 1 do
    log.info(yaml.encode(client.request('GET', 'http://localhost:22222/tarantool?command=request'..i, nil, {headers = {cookie = 'id='..1}}).body))
end

 --Revoke ip count 
try.ipt['127.0.0.1'] = 0


--Check users limit fot one ip adress
for i = 1, 11, 1 do
    log.info(client.get('http://localhost:22222/tarantool?command=limit'..i).body)
    log.info('Users count on 127.0.0.1 is', try.ipt['127.0.0.1']) 
end

try.ipt['127.0.0.1'] = 0

--Check requests for diffrent user (one cookie) 
for i = 1, 10, 1 do
log.info(yaml.encode(client.request('GET', 'http://localhost:22222/tarantool?command=user'..i, nil, {headers = {cookie = 'id='..i}}).body))
end

