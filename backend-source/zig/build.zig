const std = @import("std");

pub fn build(b: *std.Build) void {
    const lmdbModule = b.createModule(.{
        .root_source_file = b.path("lmdbModule.zig"),
    });

    const exe = b.addExecutable(.{
        .name = "Main",
        .root_source_file = b.path("Main.zig"),
        .target = b.graph.host,
    });

    exe.root_module.addImport("lmdbModule", lmdbModule);
    exe.linkSystemLibrary("c");
    exe.linkSystemLibrary("lmdb");

    b.installArtifact(exe);
}
