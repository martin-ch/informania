const std = @import("std");

pub const c = @cImport({
    @cInclude("lmdb.h");
    @cInclude("semaphore.h");
    @cInclude("fcntl.h");
    @cInclude("sys/stat.h");
});

const log = std.log.scoped(.lmdbContext);

pub const Lmdb = struct {
    allocator: std.mem.Allocator,
    dbpath: [:0]const u8,
    env: ?*c.MDB_env = undefined,
    txn: ?*c.MDB_txn = undefined,
    cur: ?*c.MDB_cursor = undefined,
    dbi: c.MDB_dbi = undefined,
    sem_name: [:0]const u8 = "/lmdb",
    sem_handle: ?*c.sem_t = undefined,
};

pub const LmdbRecord = struct {
    key: []const []const u8,
    value: []const []const u8,
};

pub const LmdbRecordUpdate = struct {
    version: []const ?u8,
    key: []const []const u8,
    value: []const []const u8,
};

// pub const result_type = enum {
//     success,
//     success_new,
//     success_new_version,
//     error_no_put,
//     error_partly_put,
//     error_dirty,
//     error_existing,
// };
