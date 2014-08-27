#!/usr/bin/env tarantool
-- This is script for starting try.tarantool

box.cfg{
    log_level = 5,
    --background = true,
    --logger = 'try.log',
    --pid_file = 'try.pid'
}

local try = require('try_tarantool')

require('console').listen('127.0.0.1:33014')
try.start()

