#!/usr/bin/env tarantool
-- This is script for starting try.tarantool

box.cfg{
    log_level = 5,
    --background = true,
    --logger = 'try.log',
    --pid_file = 'try.pid'
}

require('console').listen('127.0.0.1:33014')

local try = require('try')
try.start('0.0.0.0', 11111)
