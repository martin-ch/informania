// Sources
// http://www.lmdb.tech/doc/starting.html
// https://github.com/diogok/lmdb-zig/blob/main/src/lmdb.zig

const std = @import("std");
const c = @cImport({
    @cInclude("lmdb.h");
});

const log = std.log.scoped(.LMDB);

pub fn main() !void {
    // Prepare data
    const keys = [_][]const u8{
        "key1",
        "key2",
        "key3",
    };
    const values = [_][]const u8{
        "value1",
        "value2",
        "value3",
    };

    try (LmdbAdd(&keys, &values));
    log.info("records added to LMDB.", .{});
}

fn LmdbAdd(keys: []const []const u8, values: []const []const u8) !void {

    // Initialize environment variable
    var env: ?*c.MDB_env = undefined;

    // Create environment
    var rc = c.mdb_env_create(&env);
    if (rc != c.MDB_SUCCESS) {
        log.err("Failed to create LMDB environment: {s}", .{c.mdb_strerror(rc)});
        return error.EnvCreateFailed;
    } else {
        log.info("Env: {*}.", .{env});
    }
    defer c.mdb_env_close(env);

    // Open environment
    rc = c.mdb_env_open(env, "/opt/backend/lmdb", 0, 0o644);
    if (rc != c.MDB_SUCCESS) {
        log.err("Failed to open LMDB environment: {s}", .{c.mdb_strerror(rc)});
        return error.EnvOpenFailed;
    }

    // Initialize transaction variable
    var txn: ?*c.MDB_txn = undefined;

    // Create transaction
    rc = c.mdb_txn_begin(env, null, 0, &txn);
    if (rc != c.MDB_SUCCESS) {
        log.err("Failed to create LMDB transaction: {s}", .{c.mdb_strerror(rc)});
        return error.TransactionBeginFailed;
    } else {
        log.info("Transaction: {*}.", .{txn});
    }

    errdefer {
        c.mdb_txn_abort(txn); // abort if not committed yet
    }

    // Initialize db variable
    var dbi: c.MDB_dbi = undefined;

    rc = c.mdb_dbi_open(txn, null, 0, &dbi);
    if (rc != c.MDB_SUCCESS) {
        log.err("Failed to open LMDB database: {s}", .{c.mdb_strerror(rc)});
        return error.DbiOpenFailed;
    } else {
        log.info("Database: {d}.", .{dbi});
    }

    for (keys, values) |key, value| {
        var mdb_key = c.MDB_val{
            .mv_size = key.len,
            .mv_data = @constCast(key.ptr),
        };

        var mdb_value = c.MDB_val{
            .mv_size = value.len,
            .mv_data = @constCast(value.ptr),
        };

        // Put the key-value pair
        rc = c.mdb_put(txn, dbi, &mdb_key, &mdb_value, 0);
        if (rc != c.MDB_SUCCESS) {
            std.log.err("Failed to write to LMDB database: {s}", .{c.mdb_strerror(rc)});
            return error.MdbPutFailed;
        }
    }

    rc = c.mdb_txn_commit(txn);
    if (rc != c.MDB_SUCCESS) {
        log.err("Failed to commit LMDB transaction: {s}", .{c.mdb_strerror(rc)});
        return error.TransactionCommitFailed;
    }
}
