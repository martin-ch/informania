const std = @import("std");
const lmdb_context = @import("lmdb/context.zig");
const lmdb_init = @import("lmdb/init.zig");
const lmdb_truncate = @import("lmdb/truncate.zig");
const lmdb_put = @import("lmdb/put.zig");

pub const std_options: std.Options = .{
    .log_level = .debug,
};

const log = std.log.scoped(.Main);

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == .ok);
    const allocator = gpa.allocator();

    // // Init Write
    // var ctx = lmdb_context.Lmdb{ .allocator = allocator, .dbpath = "/opt/backend/lmdb" };
    // defer lmdb_init.deinit(&ctx);
    // try lmdb_init.init(&ctx);

    // ---------------------------------------------

    // // Init Read
    // var ctx_read = lmdb_context.Lmdb{ .allocator = allocator, .dbpath = "/opt/backend/lmdb" };
    // defer lmdb_init.deinit_read(&ctx_read);
    // try lmdb_init.init_read(&ctx_read);

    // ---------------------------------------------

    // // Truncate
    // var ctx_truncate = lmdb_context.Lmdb{ .allocator = allocator, .dbpath = "/opt/backend/lmdb" };
    // defer lmdb_init.deinit(&ctx_truncate);
    // try lmdb_init.init(&ctx_truncate);
    // try lmdb_truncate.truncate(&ctx_truncate);

    // ---------------------------------------------

    // // Put overwrite
    // var ctx_overwrite = lmdb_context.Lmdb{ .allocator = allocator, .dbpath = "/opt/backend/lmdb" };
    // defer lmdb_init.deinit(&ctx_overwrite);
    // try lmdb_init.init(&ctx_overwrite);

    // const data = lmdb_context.LmdbRecord{
    //     .key = &[_][]const u8{ "01", "02" },
    //     .value = &[_][]const u8{ "03", "04" },
    // };

    // try lmdb_put.put(&ctx_overwrite, data);

    // ---------------------------------------------

    // // Put version commit
    // var ctx_version_commit = lmdb_context.Lmdb{ .allocator = allocator, .dbpath = "/opt/backend/lmdb" };
    // defer lmdb_init.deinit(&ctx_version_commit);
    // try lmdb_init.init(&ctx_version_commit);

    // // New records
    // const dataNew = null;
    // // const dataNew = lmdb_context.LmdbRecord{
    // //     .key = &[_][]const u8{ "10", "02" },
    // //     .value = &[_][]const u8{ "11", "04" },
    // // };
    // // Update records
    // //const dataUpdate = null;
    // const dataUpdate = lmdb_context.LmdbRecordUpdate{
    //     .version = &[_]?u8{ 1, 1 },
    //     .key = &[_][]const u8{ "10", "02" },
    //     .value = &[_][]const u8{ "11", "05" },
    // };

    // try lmdb_put.put_version_commit(&ctx_version_commit, dataNew, dataUpdate);

    // ---------------------------------------------

    //const lmdbInit = @import("lmdbModule");
    // const hash_table = lmdb.hash_table;
    // var put_result = lmdb.put_result;
    // const versioning = lmdb.version_type;
    // const nats_module = nats.natsModule;

    //

    //     // LMDB
    //     var myLmdb = lmdb_module{ .allocator = allocator, .dbpath = "/opt/backend/lmdb" };

    //     try (&myLmdb).truncate();

    //     const data = &[_]hash_table{
    //         .{ .version = null, .key = "01", .value = "a" },
    //         .{ .version = 1, .key = "01", .value = "b" },
    //         .{ .version = 1, .key = "01", .value = "c" },
    //         .{ .version = 2, .key = "01", .value = "d" },
    //         .{ .version = null, .key = "01", .value = "e" },
    //         .{ .version = 1, .key = "01", .value = "f" },
    //         .{ .version = 3, .key = "01", .value = "g" },
    //         .{ .version = 4, .key = "01", .value = "h" },
    //         .{ .version = 1, .key = "01", .value = "i" },
    //     };
    //     const results = try myLmdb.put(versioning.commit, data);

    //     defer {
    //         // Free each element
    //         for (results) |res| {
    //             log.info("key='{s}', value='{s}'", .{ res.key, switch (res.result) {
    //                 .error_existing => "key not existing",
    //                 .error_dirty => "version dirty",
    //                 .error_put => "error put",
    //                 .success_new => "new",
    //                 .success_new_version => "new version",
    //             } });
    //             myLmdb.allocator.free(res.key);
    //         }
    //         // Free top-level array
    //         myLmdb.allocator.free(results);
    //     }

    //try (&myLmdb).del("02");

    // const row = try (&myLmdb).get("01", versioning.none);
    // if (row.version == null) {
    //     std.debug.print("value='{s}'\n", .{row.value});
    // } else {
    //     std.debug.print("version='{d}', value='{s}'\n", .{ row.version.?, row.value });
    // }
    // defer {
    //     allocator.free(row.value);
    // }

    // const items = try myLmdb.get_page(2, 5, versioning.none);
    // defer {
    //     for (items) |item| {
    //         allocator.free(item.key.?);
    //         allocator.free(item.value);
    //     }
    //     allocator.free(items);
    // }

    // for (items, 0..) |item, i| {
    //     if (item.version == null) {
    //         std.debug.print("Item {d}: key='{s}', value='{s}'\n", .{ i, item.key.?, item.value });
    //     } else {
    //         std.debug.print("Item {d}: version='{d}', key='{s}', value='{s}'\n", .{ i, item.version.?, item.key.?, item.value });
    //     }
    // }

    //     .{ .key = "03", .value = "c" },
    //     .{ .key = "04", .value = "d" },
    //     .{ .key = "05", .value = "e" },
    //     .{ .key = "06", .value = "f" },
    //     .{ .key = "07", .value = "g" },
    //     .{ .key = "08", .value = "h" },
    //     .{ .key = "09", .value = "i" },
    //     .{ .key = "10", .value = "j" },
    //     .{ .key = "11", .value = "k" },
    //     .{ .key = "12", .value = "l" },
    //     .{ .key = "13", .value = "m" },
    //     .{ .key = "14", .value = "n" },
    //     .{ .key = "15", .value = "o" },
    //     .{ .key = "16", .value = "p" },
    //     .{ .key = "17", .value = "q" },
    //     .{ .key = "18", .value = "r" },
    //     .{ .key = "19", .value = "s" },
    //     .{ .key = "20", .value = "t" },
    // });

}
