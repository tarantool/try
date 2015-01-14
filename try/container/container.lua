#!/usr/bin/env tarantool

---
--- Script for container
---

box.cfg {
    slab_alloc_arena = 0.5;
    wal_mode = "none"
}

--
-- Add minimal sandboxing
--
os.execute = nil
os.exit = nil
os.rename = nil
os.tmpname = nil
os.remove = nil
io = nil
package.loaded.socket = nil
package.loaded.fio = nil
package = nil

require('console').listen('0.0.0.0:3313')
