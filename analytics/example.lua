#!/usr/bin/env/tarantool

local http = require('http.server')
local http_router = require('http.router')
local httpd = http.new('0.0.0.0', '5050')
local router = http_router.new()
httpd:set_router(router)

local front = require('frontend-core')
local analytics = require('analytics')

front.add('analytics_static', analytics.static_bundle)
front.add('ga', analytics.use_bundle({ ga = '22120502-2' }))

front.init(router)

httpd:start()
