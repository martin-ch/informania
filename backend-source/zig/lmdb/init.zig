const std = @import("std");
const ctx = @import("context.zig");

const log = std.log.scoped(.lmdbInit);

pub fn init(context: *ctx.Lmdb) !void {

    // Create semaphore
    context.sem_handle = ctx.c.sem_open(context.sem_name, @as(c_int, ctx.c.O_CREAT | ctx.c.O_EXCL), @as(c_uint, 0o666), @as(c_uint, 1));
    // Try opening new semaphore
    if (context.sem_handle == ctx.c.SEM_FAILED) {
        // Try opening existing semaphore
        context.sem_handle = ctx.c.sem_open(context.sem_name, 0);
        if (context.sem_handle == ctx.c.SEM_FAILED) {
            return error.SemOpenExistingFailed;
        }
        // Semaphore was aquired. Wait until it's free
        if (ctx.c.sem_wait(context.sem_handle) != 0) {
            return error.SemWaitFailed;
        }
    }

    // Create environment
    if (ctx.c.mdb_env_create(&context.env) != ctx.c.MDB_SUCCESS) {
        return error.EnvCreateFailed;
    }

    // Open environment
    if (ctx.c.mdb_env_open(context.env, context.dbpath.ptr, 0, 0o644) != ctx.c.MDB_SUCCESS) {
        return error.EnvOpenFailed;
    }

    // Clear stale readers
    var count_stale_readers: c_int = 0;
    const rc = ctx.c.mdb_reader_check(context.env, &count_stale_readers);
    if (rc != ctx.c.MDB_SUCCESS) {
        return error.ClearStaleReadersFailed;
    }
    log.info("Number of stale slots that were cleared: {}\n", .{count_stale_readers});

    // Create transaction
    if (ctx.c.mdb_txn_begin(context.env, null, 0, &context.txn) != ctx.c.MDB_SUCCESS) {
        return error.TransactionBeginFailed;
    }
    // Open database
    if (ctx.c.mdb_dbi_open(context.txn, null, 0, &context.dbi) != ctx.c.MDB_SUCCESS) {
        return error.DbiOpenFailed;
    }
}

pub fn deinit(context: *ctx.Lmdb) void {

    // Abort transaction if it wasn't formerly commited
    if (context.txn != null) {
        ctx.c.mdb_txn_abort(context.txn);
        context.txn = null;
    }

    // Close environment
    if (context.env != null) {
        ctx.c.mdb_env_close(context.env);
        context.dbi = 0;
        context.env = null;
    }
    _ = ctx.c.sem_post(context.sem_handle);
    _ = ctx.c.sem_close(context.sem_handle);
}

pub fn init_read(context: *ctx.Lmdb) !void {

    // Create environment
    if (ctx.c.mdb_env_create(&context.env) != ctx.c.MDB_SUCCESS) {
        return error.EnvCreateFailed;
    }

    // Open environment
    if (ctx.c.mdb_env_open(context.env, context.dbpath.ptr, 0, 0o644) != ctx.c.MDB_SUCCESS) {
        return error.EnvOpenFailed;
    }

    // Create transaction
    if (ctx.c.mdb_txn_begin(context.env, null, ctx.c.MDB_RDONLY, &context.txn) != ctx.c.MDB_SUCCESS) {
        return error.TransactionBeginFailed;
    }
    // Open database
    if (ctx.c.mdb_dbi_open(context.txn, null, 0, &context.dbi) != ctx.c.MDB_SUCCESS) {
        return error.DbiOpenFailed;
    }
}

pub fn deinit_read(context: *ctx.Lmdb) void {

    // Abort transaction if it wasn't formerly commited
    if (context.txn != null) {
        ctx.c.mdb_txn_abort(context.txn);
        context.txn = null;
    }

    // Close environment
    if (context.env != null) {
        ctx.c.mdb_env_close(context.env);
        context.dbi = 0;
        context.env = null;
    }
}
