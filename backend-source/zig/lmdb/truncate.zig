const std = @import("std");
const ctx = @import("context.zig");

const log = std.log.scoped(.lmdbTruncate);

pub fn truncate(context: *ctx.Lmdb) !void {
    // Truncate database
    if (ctx.c.mdb_drop(context.txn, context.dbi, 0) != ctx.c.MDB_SUCCESS) {
        return error.TransactionDropFailed;
    }

    // Commit Transaction
    if (ctx.c.mdb_txn_commit(context.txn) != ctx.c.MDB_SUCCESS) {
        return error.TransactionCommitFailed;
    } else {
        context.txn = null;
    }
}
