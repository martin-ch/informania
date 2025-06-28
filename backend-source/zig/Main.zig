const std = @import("std");
const lmdb = @import("lmdbModule");
const nats = @import("natsModule");
const lmdb_module = lmdb.lmdbModule;
const hash_table = lmdb.hash_table;
const nats_module = nats.natsModule;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == .ok);
    const allocator = gpa.allocator();

    // NATS
    var myNats = nats_module{ .url = "nats://nats:4222", .subj = "lmdb.write" };
    try (&myNats).run(allocator);

    // // LMDB
    // var myLmdb = lmdb_module{ .path = "/opt/backend/lmdb" };

    // try (&myLmdb).truncate();

    // try myLmdb.put(&[_]hash_table{
    //     .{ .key = "01", .value = "a" },
    //     .{ .key = "02", .value = "b" },
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

    // try (&myLmdb).del("02");

    // const items = try myLmdb.get_page(allocator, 2, 5);
    // for (items, 0..) |item, i| {
    //     std.debug.print("Item {d}: key='{s}', value='{s}'\n", .{ i, item.key, item.value });
    // }

    // defer {
    //     for (items) |item| {
    //         allocator.free(item.key);
    //         allocator.free(item.value);
    //     }
    //     allocator.free(items);
    // }

    // const val = try (&myLmdb).get(allocator, "01");
    // std.debug.print("Got: {s}\n", .{val});
    // defer allocator.free(val);
}
