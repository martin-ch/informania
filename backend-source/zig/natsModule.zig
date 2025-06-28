const std = @import("std");
// const lmdbModule = @import("lmdbModule.zig"); // if in same folder
const c = @cImport({
    @cInclude("/opt/vcpkg/installed/x64-linux/include/nats/nats.h");
});

const log = std.log.scoped(.NATS);

pub const natsModule = struct {
    url: []const u8,
    subj: [:0]const u8,
    conn: ?*c.natsConnection = null,
    opts: ?*c.natsOptions = undefined,
    subs: ?*c.natsSubscription = undefined,

    pub fn run(self: *natsModule, allocator: std.mem.Allocator) !void {

        // Initialized Option variable
        if (c.natsOptions_Create(&self.opts) != c.NATS_OK) return error.OptionsCreateFailed;
        defer self.deinit();

        // Set URL
        if (c.natsOptions_SetURL(self.opts.?, self.url.ptr) != c.NATS_OK) return error.SetUrlFailed;

        const status = c.natsConnection_Connect(&self.conn, self.opts.?); // You can create and configure options if needed
        log.info("Connection status: {s}\n", .{c.natsStatus_GetText(status)});

        if (status != c.NATS_OK) {
            return error.ConnectionFailed;
        }

        var counter: i32 = 0;

        var sub: ?*c.natsSubscription = null;
        if (c.natsConnection_Subscribe(&sub, self.conn, self.subj, onMsg, &counter) != c.NATS_OK) {
            return error.SubscribeFailed;
        }

        log.info("Subscribed to '{s}'", .{self.subj});
        //nats --context nats.backend req lmdb.write "your request message"
        _ = allocator;

        // Keep running
        while (true) std.time.sleep(1_000_000_000); // 1 second

    }

    fn deinit(self: *natsModule) void {
        if (self.conn) |conn| c.natsConnection_Destroy(conn);
        if (self.opts) |opts| c.natsOptions_Destroy(opts);
        log.info("Connections destroyed\n", .{});
    }

    pub fn onMsg(
        conn: ?*c.natsConnection,
        sub: ?*c.natsSubscription,
        msg: ?*c.natsMsg,
        closure: ?*anyopaque,
    ) callconv(.C) void {
        _ = sub;

        const reply = c.natsMsg_GetReply(msg);
        if (reply == null) return;

        // Cast closure to i32 pointer
        const counter_ptr = @as(*i32, @ptrCast(@alignCast(closure.?)));
        counter_ptr.* += 1;

        var buf: [64]u8 = undefined;
        const printed = std.fmt.bufPrint(&buf, "Count: {d}", .{counter_ptr.*}) catch return;
        if (printed.len >= buf.len) return;
        buf[printed.len] = 0;

        _ = c.natsConnection_PublishString(conn, reply, @ptrCast(&buf[0]));
        c.natsMsg_Destroy(msg);

        // _ = sub;
        // _ = closure;
        // const reply = c.natsMsg_GetReply(msg);
        // if (reply == null) return;

        // var buf: [64]u8 = undefined;
        // const now = std.time.timestamp();
        // const printed = std.fmt.bufPrint(&buf, "Time is: {d}", .{now}) catch return;
        // _ = printed;
        // _ = c.natsConnection_PublishString(
        //     conn,
        //     reply,
        //     @ptrCast(&buf[0]),
        // );
        // c.natsMsg_Destroy(msg);

        ////////////////////////////////

        //         const data_len = c.natsMsg_GetDataLength(msg);
        // // Convert length (c_int) to usize safely
        // const len: usize = if (data_len < 0) 0 else @intCast(data_len);

        // // Format the length as a string into a buffer
        // var buf: [20]u8 = undefined;
        // const len_str = std.fmt.intToBuf(u64, len, 10, &buf);

        // // Publish the length string as a reply
        // _ = c.natsConnection_Publish(conn, reply, len_str.ptr, len_str.len);

        // _ = c.natsConnection_Publish(
        //     conn,
        //     reply,
        //     &buf[0],
        //     @intCast(printed.len),
    }
};
// Reply message function
// pub fn onMsg(
//     conn: ?*c.natsConnection,
//     sub: ?*c.natsSubscription,
//     msg: ?*c.natsMsg,
//     closure: ?*anyopaque,
// ) callconv(.C) void {
//     _ = sub;

//     const reply = c.natsMsg_GetReply(msg);
//     if (msg == null or closure == null) return;

//     const data = c.natsMsg_GetData(msg);
//     const data_len = c.natsMsg_GetDataLength(msg);
//     const json_bytes = data[0..@intCast(data_len)];

//     // Reinterpret closure as *lmdbModule
//     const lmdb = @as(*lmdbModule, @ptrCast(closure.?));

//     const allocator = std.heap.page_allocator;

//     var parsed = std.json.parseFromSlice(std.json.Value, allocator, json_bytes, .{}) catch {
//         if (reply != null) _ = c.natsConnection_Publish(conn, reply, "JSON_ERROR", 10);
//         c.natsMsg_Destroy(msg);
//         return;
//     };
//     defer parsed.deinit();

//     const obj = parsed.value;
//     if (obj.get("key") == null or obj.get("value") == null) {
//         if (reply != null) _ = c.natsConnection_Publish(conn, reply, "MISSING_FIELDS", 14);
//         c.natsMsg_Destroy(msg);
//         return;
//     }

//     const key_str = obj.get("key").?.string catch {
//         if (reply != null) _ = c.natsConnection_Publish(conn, reply, "INVALID_KEY", 11);
//         c.natsMsg_Destroy(msg);
//         return;
//     };

//     const val_str = obj.get("value").?.string catch {
//         if (reply != null) _ = c.natsConnection_Publish(conn, reply, "INVALID_VAL", 11);
//         c.natsMsg_Destroy(msg);
//         return;
//     };

//     const item = [_]lmdbModule.hash_table{
//         .{ .key = key_str, .value = val_str },
//     };

//     const result = lmdb.put(&item);

//     if (reply != null) {
//         const resp = switch (result) {
//             error.PutFailed => "PUT_FAIL",
//             error.TransactionCommitFailed => "TXN_FAIL",
//             else => "OK",
//         };
//         _ = c.natsConnection_Publish(conn, reply, resp.ptr, resp.len);
//     }

//     c.natsMsg_Destroy(msg);
// }
