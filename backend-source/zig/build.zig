const std = @import("std");

pub fn build(b: *std.Build) void {
    const exe = b.addExecutable(.{
        .name = "Main",
        .root_source_file = b.path("main.zig"),
        .target = b.graph.host,
    });

    exe.linkSystemLibrary("c");
    exe.linkSystemLibrary("lmdb");

    b.installArtifact(exe);
}
