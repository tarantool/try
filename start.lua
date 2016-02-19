#!/usr/bin/env tarantool

box.cfg{}

local try = require('try')
try.start('0.0.0.0', 11111)
