#!/usr/bin/env tarantool
-- This is script for start testing try.tarantool

local log = require('log')
local client = require('http.client')
local yaml = require('yaml')
local fiber = require('fiber')
local tap = require('tap')
local CONSOLE_PORT = '33014'

box.cfg{
    log_level = 5,
}

local try = require('try_tarantool')
local test = tap.test('try')

require('console').listen('127.0.0.1:'..CONSOLE_PORT)

log.info('Start try.tarantool tests')
try.CONTAINER_PORT = '33001'
try.start_container = function() return '127.0.0.1', CONSOLE_PORT end
try.remove_container = function() log.info('Test remove done') end
try.clear_lxc = function() log.info('Test lsc clear done') fiber.sleep(1800) end

local function get_req (url, id)
    if id == nil then
        return client.get(url).body
    else
        return client.request('GET', url, nil, {headers = {cookie = 'id='..id}}).body
    end
end

try.start()
test:plan(3)

test:test('Check socket error', function(test)
    test:plan(1)
    local inf = get_req('http://localhost:22222/tarantool?command=help', 1)
    test:is(inf, 'Sorry! Server have problem with socket. Please update web page.')
end)

try.CONTAINER_PORT = CONSOLE_PORT

test:test('Check requests for one user (one cookie)', function(test) 
    test:plan(5)
    for i = 1, 5, 1 do
        local inf = get_req('http://localhost:22222/tarantool?command=2*'..i, 1)
        test:is(yaml.decode(inf)[1], i*2)
    end
end)

--Revoke ip count 
try.ipt['127.0.0.1'] = 0

test:test('Check users limit for one ip adress', function(test)
    test:plan(1)
    local inf = 0
    for i = 1, 10, 1 do
        inf = get_req('http://localhost:22222/tarantool?command=limit'..i)
        inf = client.get('http://localhost:22222/tarantool?command=limit'..i).body
    end
    inf = get_req('http://localhost:22222/tarantool?command=limit'..11)
    test:is(inf, 'Sorry! Users limit exceeded! Please, close some session.')
end)

try.ipt['127.0.0.1'] = 0

test:test('Check requests for diffrent user (one cookie) ', function(test)
    test:plan(10)
    for i = 1, 10, 1 do
        local inf = get_req('http://localhost:22222/tarantool?command=10*'..i, i)
        test:is(yaml.decode(inf)[1], i*10)
    end
end)

