const std = @import("std");
const ctx = @import("context.zig");

const log = std.log.scoped(.lmdbPut);

pub fn put(context: *ctx.Lmdb, items: ctx.LmdbRecord) !void {

    // Loop over items
    for (items.key, items.value) |key, value| {
        // Convert key and value to LMDB objects;
        var k = ctx.c.MDB_val{ .mv_size = key.len, .mv_data = @constCast(key.ptr) };
        var v = ctx.c.MDB_val{ .mv_size = value.len, .mv_data = @constCast(value.ptr) };

        if (ctx.c.mdb_put(context.txn, context.dbi, &k, &v, 0) != ctx.c.MDB_SUCCESS) {
            log.debug("Error putting record with key '{s}' and value '{s}'", .{ key, value });
            return error.PutFailed;
        }
    }

    // Commit Transaction
    if (ctx.c.mdb_txn_commit(context.txn) != ctx.c.MDB_SUCCESS) {
        return error.TransactionCommitFailed;
    } else {
        context.txn = null;
    }
}

pub fn put_version_commit(context: *ctx.Lmdb, items_new: ?ctx.LmdbRecord, items_update: ?ctx.LmdbRecordUpdate) !void {

    // Check dirty

    // Check dirty: New
    if (items_new) |new_items| {
        for (new_items.key) |key| {
            // Convert key to an LMDB object;
            var k = ctx.c.MDB_val{ .mv_size = key.len, .mv_data = @constCast(key.ptr) };
            var v: ctx.c.MDB_val = undefined;

            const rc = ctx.c.mdb_get(context.txn, context.dbi, &k, &v);
            // Record can't exist in LMDB
            if (rc == ctx.c.MDB_SUCCESS) {
                log.debug("Error put_version_commmit: new key exists '{s}'", .{key});
                return error.PutDirtyKeyFound;
            } else if (rc != ctx.c.MDB_NOTFOUND and rc != ctx.c.MDB_SUCCESS) {
                return error.PutFailed;
            }
        }
    }

    // Check dirty: Update
    if (items_update) |update_items| {
        for (update_items.key, update_items.version) |key, version| {
            // Convert key to an LMDB object;
            var k = ctx.c.MDB_val{ .mv_size = key.len, .mv_data = @constCast(key.ptr) };
            var v: ctx.c.MDB_val = undefined;

            const rc = ctx.c.mdb_get(context.txn, context.dbi, &k, &v);
            // Sent version has to match the version in LMDB. For new records, version null has to be sent.
            if (rc == ctx.c.MDB_SUCCESS and version != @as([*]const u8, @ptrCast(v.mv_data))[0]) {
                log.debug("Error put_version_commmit: dirty for key '{s}'. Version sent: '{d}', Version in LMDB: '{d}'.", .{ key, version orelse unreachable, @as([*]const u8, @ptrCast(v.mv_data))[0] });
                return error.PutDirtyVersion;
            } else if (rc == ctx.c.MDB_NOTFOUND) {
                log.debug("Error put_version_commmit: key '{s}' not found", .{key});
                return error.PutDirtyKeyNotFound;
            } else if (rc != ctx.c.MDB_NOTFOUND and rc != ctx.c.MDB_SUCCESS) {
                return error.PutFailed;
            }
        }
    }

    // Put items

    // New
    if (items_new) |new_items| {
        for (new_items.key, new_items.value) |key, value| {

            // Prefix new row with 1
            var value_buf = try context.allocator.alloc(u8, value.len + 1);
            defer context.allocator.free(value_buf);
            value_buf[0] = 1; // initial row version is 1
            @memcpy(value_buf[1..], value);

            // Convert key and value to LMDB objects;
            var k = ctx.c.MDB_val{ .mv_size = key.len, .mv_data = @constCast(key.ptr) };
            var v = ctx.c.MDB_val{ .mv_size = value_buf.len, .mv_data = @constCast(value_buf.ptr) };

            if (ctx.c.mdb_put(context.txn, context.dbi, &k, &v, 0) != ctx.c.MDB_SUCCESS) {
                log.debug("Error putting new record with key '{s}' and value '{s}'", .{ key, value });
                return error.PutNewFailed;
            }
        }
    }

    // Update
    if (items_update) |update_items| {
        for (update_items.key, update_items.version, update_items.value) |key, version, value| {

            // Prefix new row with 1
            var value_buf = try context.allocator.alloc(u8, value.len + 1);
            defer context.allocator.free(value_buf);
            value_buf[0] = (version orelse unreachable) +% 1; //increment version, +% ensures wrapping
            @memcpy(value_buf[1..], value);

            // Convert key and value to LMDB objects;
            var k = ctx.c.MDB_val{ .mv_size = key.len, .mv_data = @constCast(key.ptr) };
            var v = ctx.c.MDB_val{ .mv_size = value_buf.len, .mv_data = @constCast(value_buf.ptr) };

            if (ctx.c.mdb_put(context.txn, context.dbi, &k, &v, 0) != ctx.c.MDB_SUCCESS) {
                log.debug("Error putting new record with key '{s}', value '{s}' and new version '{d}'", .{ key, value, (version orelse unreachable) +% 1 });
                return error.PutNewFailed;
            }
        }
    }

    // Commit Transaction
    if (ctx.c.mdb_txn_commit(context.txn) != ctx.c.MDB_SUCCESS) {
        return error.TransactionCommitFailed;
    } else {
        context.txn = null;
    }
}

// Put row version
