#!/usr/bin/env tarantool

---
--- Script for container
---

box.cfg {
    memtx_memory = 128*1024*1024;
    wal_mode = "none"
}

require('console').listen('0.0.0.0:3313')
