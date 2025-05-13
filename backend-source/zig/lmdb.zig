// Sources
// http://www.lmdb.tech/doc/starting.html
// https://github.com/diogok/lmdb-zig/blob/main/src/lmdb.zig

const std = @import("std");
const c = @cImport({
    @cInclude("lmdb.h");
});

const log = std.log.scoped(.LMDB);

pub fn main() !void {

    // LMDB environment setup
    var env: ?*c.MDB_env = undefined;

    // Create environment
    const rc = c.mdb_env_create(&env);
    if (rc != c.MDB_SUCCESS) {
        std.log.err("Failed to create LMDB environment: {s}", .{c.mdb_strerror(rc)});
        return error.EnvCreateFailed;
    } else {
        log.info("Env: {*}.", .{env});
    }

    defer c.mdb_env_close(env);
}
