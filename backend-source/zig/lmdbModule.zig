const std = @import("std");
const c = @cImport({
    @cInclude("semaphore.h");
    @cInclude("fcntl.h");
    @cInclude("sys/stat.h");
    @cInclude("lmdb.h");
});

const log = std.log.scoped(.LMDB);

pub const version_type = enum(u8) {
    none = 0,
    row = 1,
    commit = 2,
};

pub const hash_table = struct {
    version: ?u8,
    key: ?[]const u8,
    value: []const u8,
};

pub const put_result = struct {
    key: []u8,
    result: result_type,
};

pub const result_type = enum {
    success_new,
    success_new_version,
    error_put,
    error_dirty,
    error_existing,
};

pub const lmdbModule = struct {
    allocator: std.mem.Allocator,
    sem_name: [:0]const u8 = "/lmdb",
    sem: ?*c.sem_t = undefined,
    dbpath: [:0]const u8,
    env: ?*c.MDB_env = undefined,
    txn: ?*c.MDB_txn = undefined,
    cur: ?*c.MDB_cursor = undefined,
    dbi: c.MDB_dbi = undefined,

    pub fn get(self: *lmdbModule, key: []const u8, versioning: version_type) !hash_table {
        defer self.deinit(c.MDB_RDONLY);
        try self.init(c.MDB_RDONLY);

        return get_priv(self, key, versioning);
    }

    fn get_priv(self: *lmdbModule, key: []const u8, versioning: version_type) !hash_table {

        // Convert key to an LMDB object;
        var k = c.MDB_val{ .mv_size = key.len, .mv_data = @constCast(key.ptr) };
        var v: c.MDB_val = undefined;

        const rc = c.mdb_get(self.txn, self.dbi, &k, &v);
        switch (rc) {
            c.MDB_SUCCESS => {
                var ver: ?u8 = null;
                var val = @as([*]const u8, @ptrCast(v.mv_data))[0..v.mv_size];

                if (versioning != version_type.none) {
                    ver = val[0];
                    val = val[1..];
                }

                const val_copy = try self.allocator.dupe(u8, val);
                return hash_table{
                    .version = ver,
                    .key = null,
                    .value = val_copy,
                };
            },
            c.MDB_NOTFOUND => return error.GetKeyNotFound,
            else => return error.GetFailed,
        }
    }

    pub fn get_page(self: *lmdbModule, page: usize, page_size: usize, versioning: version_type) ![]hash_table {
        var cur_pos: c.MDB_cursor_op = c.MDB_FIRST;
        var k: c.MDB_val = undefined;
        var v: c.MDB_val = undefined;

        var entries = std.ArrayList(hash_table).init(self.allocator);
        errdefer entries.deinit();

        defer self.deinit(c.MDB_RDONLY);
        try self.init(c.MDB_RDONLY);

        // Open cursor
        if (c.mdb_cursor_open(self.txn, self.dbi, &self.cur) != c.MDB_SUCCESS) {
            return error.CursorOpenFailed;
        }

        defer c.mdb_cursor_close(self.cur);

        var i: usize = 0;
        const b_all: bool = (page == 0 or page_size == 0);
        const i_end: usize = page * page_size;
        const i_bgn: usize = i_end - page_size + 1;

        // Retrieve records for the requested page
        while (c.mdb_cursor_get(self.cur, &k, &v, cur_pos) == c.MDB_SUCCESS) {
            i += 1;

            if (b_all or (i_bgn <= i and i_end >= i)) {
                var ver: ?u8 = null;
                const key = @as([*]const u8, @ptrCast(k.mv_data))[0..k.mv_size];
                var val = @as([*]const u8, @ptrCast(v.mv_data))[0..v.mv_size];

                if (versioning != version_type.none) {
                    ver = val[0];
                    val = val[1..];
                }

                const key_copy = try self.allocator.dupe(u8, key);
                const val_copy = try self.allocator.dupe(u8, val);

                try entries.append(.{
                    .version = ver,
                    .key = key_copy,
                    .value = val_copy,
                });
            }

            cur_pos = c.MDB_NEXT;
        }

        return entries.toOwnedSlice();
    }

    pub fn put(self: *lmdbModule, versioning: version_type, items: []const hash_table) ![]put_result {
        defer self.deinit(0);
        try self.init(0);

        // Clean up stale transactions
        try self.clear_stale_readers();

        //const results = try self.allocator.alloc(put_result, items.len);
        //errdefer self.allocator.free(results);

        // Check If all rows are clean
        if (versioning == version_type.commit) {
            const dirty = try check_dirty(self, items);
            if (dirty.len != 0) {
                return dirty;
            } else {
                self.allocator.free(dirty);
            }
        }

        // Loop over items
        for (items, 0..) |item, i| {

            // We only need to check the version when versioning by row. For versioning by commit we already checked through fn check_dirty.
            var flags: c_int = undefined;
            switch (versioning) {
                version_type.row => flags = c.MDB_NOOVERWRITE,
                else => flags = 0,
            }

            _ = item;
            _ = i;
        }

        //     // Prefix row version. Try 0 and if the record exist, use version += 1
        //     var value_buf = try self.allocator.alloc(u8, item.value.len + 1);
        //     defer self.allocator.free(value_buf);
        //     value_buf[0] = 1; // initial row version is 1
        //     @memcpy(value_buf[1..], item.value);

        //     var res_type: result_type = null;
        //     while (true) {
        //         // Convert key and value to LMDB objects;
        //         var k = c.MDB_val{ .mv_size = item.key.len, .mv_data = @constCast(item.key.ptr) };
        //         var v = c.MDB_val{ .mv_size = value_buf.len, .mv_data = @constCast(value_buf.ptr) };

        //         // Write Key / Value
        //         try switch (c.mdb_put(self.txn, self.dbi, &k, &v, flags)) {
        //             c.MDB_SUCCESS => {
        //                 res_type = result_type.success_new;
        //                 break;
        //             },
        //             c.MDB_KEYEXIST => {
        //                 flags = 0; // allow overwrite
        //                 value_buf[0] = @as(*u8, @ptrCast(v.mv_data)).* +% 1; //increment version, +% ensures wrapping
        //                 res_type = result_type.success_new_version;
        //                 log.debug("Key '{s}' exists, overwriting with version '{d}'", .{ item.key, value_buf[0] });
        //             },
        //             else => {
        //                 res_type = result_type.error_put;
        //                 error.PutFailed;
        //             },
        //         };
        //     }
        //     results[i] = put_result{
        //         .key = try self.allocator.dupe(u8, item.key),
        //         .result = res_type,
        //     };
        // }
        // // Commit Transaction
        // if (c.mdb_txn_commit(self.txn) != c.MDB_SUCCESS) {
        //     return error.TransactionCommitFailed;
        // } else {
        //     self.txn = null;
        // }
        //return results;
        return error.whatamess;
    }

    fn check_dirty(self: *lmdbModule, items: []const hash_table) ![]put_result {
        var results = std.ArrayList(put_result).init(self.allocator);
        defer results.deinit();

        for (items) |item| {
            var res_type: ?result_type = null;
            const res: hash_table = get_priv(self, item.key.?, version_type.commit) catch |err| blk: {
                switch (err) {
                    error.GetKeyNotFound => {
                        if (item.version != null) {
                            res_type = .error_existing;
                        }
                    },
                    else => {
                        res_type = .error_put;
                    },
                }
                break :blk hash_table{
                    .version = null,
                    .key = null,
                    .value = &[_]u8{},
                };
            };

            // No error found yet
            if (res_type == null) {
                if (res.version != item.version) {
                    res_type = .error_dirty;
                }
            }

            // Append error to result
            if (res_type != null) {
                try results.append(.{
                    .key = try self.allocator.dupe(u8, item.key.?),
                    .result = res_type.?,
                });
            }
        }

        return results.toOwnedSlice();
    }

    pub fn del(self: *lmdbModule, key: []const u8) !void {
        defer self.deinit(0);
        try self.init(0);

        // Convert key to an LMDB object;
        var k = c.MDB_val{ .mv_size = key.len, .mv_data = @constCast(key.ptr) };

        // Delete Key
        const rc = c.mdb_del(self.txn, self.dbi, &k, null);
        switch (rc) {
            c.MDB_SUCCESS => {
                // Commit Transaction
                if (c.mdb_txn_commit(self.txn) != c.MDB_SUCCESS) {
                    return error.TransactionCommitFailed;
                } else {
                    self.txn = null;
                }
            },
            c.MDB_NOTFOUND => return error.DelKeyNotFound,
            else => return error.DelFailed,
        }
    }

    pub fn truncate(self: *lmdbModule) !void {
        defer self.deinit(0);
        try self.init(0);

        // Truncate database
        if (c.mdb_drop(self.txn, self.dbi, 0) != c.MDB_SUCCESS) {
            return error.TransactionDropFailed;
        }

        // Commit Transaction
        if (c.mdb_txn_commit(self.txn) != c.MDB_SUCCESS) {
            return error.TransactionCommitFailed;
        } else {
            self.txn = null;
        }
    }

    fn init(self: *lmdbModule, flags: c.uint) !void {

        // Create semaphore
        if (flags != c.MDB_RDONLY) {
            self.sem = c.sem_open(self.sem_name, @as(c_int, c.O_CREAT | c.O_EXCL), @as(c_uint, 0o666), @as(c_uint, 1));
            // Try opening new semaphore
            if (self.sem == c.SEM_FAILED) {
                // Try opening existing semaphore
                self.sem = c.sem_open(self.sem_name, 0);
                if (self.sem == c.SEM_FAILED) {
                    return error.SemOpenExistingFailed;
                }
            }
            // Semaphore was aquired. Wait until it's free
            if (c.sem_wait(self.sem) != 0) {
                return error.SemWaitFailed;
            }
        }

        // Create environment
        if (c.mdb_env_create(&self.env) != c.MDB_SUCCESS) {
            return error.EnvCreateFailed;
        }

        // Open environment
        if (c.mdb_env_open(self.env, self.dbpath.ptr, 0, 0o644) != c.MDB_SUCCESS) {
            return error.EnvOpenFailed;
        }

        // Create transaction
        if (c.mdb_txn_begin(self.env, null, flags, &self.txn) != c.MDB_SUCCESS) {
            return error.TransactionBeginFailed;
        }
        // Open database
        if (c.mdb_dbi_open(self.txn, null, 0, &self.dbi) != c.MDB_SUCCESS) {
            return error.DbiOpenFailed;
        }
    }

    fn deinit(self: *lmdbModule, flags: c.uint) void {

        // Abort transaction if it wasn't formerly commited
        if (self.txn != null) {
            c.mdb_txn_abort(self.txn);
            self.txn = null;
        }

        // Close environment
        if (self.env != null) {
            c.mdb_env_close(self.env);
            self.dbi = 0;
            self.env = null;
        }

        // Release and close semaphore
        if (flags != c.MDB_RDONLY) {
            _ = c.sem_post(self.sem);
            _ = c.sem_close(self.sem);
        }
    }

    fn clear_stale_readers(self: *lmdbModule) !void {
        var dead_readers: c_int = 0;
        const rc = c.mdb_reader_check(self.env, &dead_readers);
        if (rc != c.MDB_SUCCESS) {
            return error.ClearStaleReadersFailed;
        }
    }
};
