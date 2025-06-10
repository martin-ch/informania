const std = @import("std");
const c = @cImport({
    @cInclude("lmdb.h");
});

const log = std.log.scoped(.LMDB);

pub const hash_table = struct {
    key: []const u8,
    value: []const u8,
};

pub const lmdbModule = struct {
    path: [:0]const u8,
    env: ?*c.MDB_env = undefined,
    txn: ?*c.MDB_txn = undefined,
    cur: ?*c.MDB_cursor = undefined,
    dbi: c.MDB_dbi = undefined,

    pub fn get(self: *lmdbModule, key: []const u8) ![]const u8 {
        defer self.deinit();
        try self.init(c.MDB_RDONLY);

        // Convert key to an LMDB object;
        var k = c.MDB_val{ .mv_size = key.len, .mv_data = @constCast(key.ptr) };
        var v: c.MDB_val = undefined;

        const rc = c.mdb_get(self.txn, self.dbi, &k, &v);
        switch (rc) {
            c.MDB_SUCCESS => {
                const src = @as([*]const u8, @ptrCast(v.mv_data))[0..v.mv_size];
                const cpy = try std.heap.page_allocator.dupe(u8, src);
                return cpy;
            },
            c.MDB_NOTFOUND => return error.GetKeyNotFound,
            else => return error.GetFailed,
        }
    }

    pub fn get_page(self: *lmdbModule, page: usize, page_size: usize) ![]hash_table {
        var cur_pos: c.MDB_cursor_op = c.MDB_FIRST;
        var k: c.MDB_val = undefined;
        var v: c.MDB_val = undefined;

        const allocator = std.heap.page_allocator;
        var entries = std.ArrayList(hash_table).init(allocator);
        defer entries.deinit();

        defer self.deinit();
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
                const key = @as([*]const u8, @ptrCast(k.mv_data))[0..k.mv_size];
                const val = @as([*]const u8, @ptrCast(v.mv_data))[0..v.mv_size];

                const key_copy = try std.heap.page_allocator.dupe(u8, key);
                const val_copy = try std.heap.page_allocator.dupe(u8, val);

                try entries.append(.{
                    .key = key_copy,
                    .value = val_copy,
                });
            }

            cur_pos = c.MDB_NEXT;
        }

        return entries.toOwnedSlice();
    }

    pub fn put(self: *lmdbModule, items: []const hash_table) !void {
        defer self.deinit();
        try self.init(0);

        // Clean up stale transactions
        try self.clear_stale_readers();

        // Loop over items
        for (items) |item| {
            // Convert key and value to LMDB objects;
            var k = c.MDB_val{ .mv_size = item.key.len, .mv_data = @constCast(item.key.ptr) };
            var v = c.MDB_val{ .mv_size = item.value.len, .mv_data = @constCast(item.value.ptr) };

            // Write Key / Value
            if (c.mdb_put(self.txn, self.dbi, &k, &v, 0) != c.MDB_SUCCESS) {
                return error.PutFailed;
            }
        }
        // Commit Transaction
        if (c.mdb_txn_commit(self.txn) != c.MDB_SUCCESS) {
            return error.TransactionCommitFailed;
        } else {
            self.txn = null;
        }
    }

    pub fn del(self: *lmdbModule, key: []const u8) !void {
        defer self.deinit();
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
        defer self.deinit();
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
        // Create environment
        if (c.mdb_env_create(&self.env) != c.MDB_SUCCESS) {
            return error.EnvCreateFailed;
        }

        // Open environment
        if (c.mdb_env_open(self.env, self.path.ptr, 0, 0o644) != c.MDB_SUCCESS) {
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

    fn deinit(self: *lmdbModule) void {
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
    }

    fn clear_stale_readers(self: *lmdbModule) !void {
        var dead_readers: c_int = 0;
        const rc = c.mdb_reader_check(self.env, &dead_readers);
        if (rc != c.MDB_SUCCESS) {
            return error.ClearStaleReadersFailed;
        }
    }
};
