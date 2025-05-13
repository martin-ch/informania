const std = @import("std");

pub fn build(b: *std.Build) void {
    const exe = b.addExecutable(.{
        .name = "lmdb",
        .root_source_file = b.path("lmdb.zig"),
        .target = b.graph.host,
    });

    exe.linkSystemLibrary("lmdb");
    exe.linkSystemLibrary("c");
    b.installArtifact(exe);
}
