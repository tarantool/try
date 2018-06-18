#!/usr/bin/env tarantool

box.cfg{ log_level = 5 }

local try = require('try')
try.start('0.0.0.0', 11112)
