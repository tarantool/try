#!/usr/bin/env tarantool

---
--- Script for container
---

box.cfg {
    admin = 3313;
    slab_alloc_arena = 0.5;
    wal_mode = "none"
}
