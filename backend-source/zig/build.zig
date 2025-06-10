const std = @import("std");

pub fn build(b: *std.Build) void {
    const lmdbModule = b.createModule(.{
        .root_source_file = b.path("lmdbModule.zig"),
    });

    const exe = b.addExecutable(.{
        .name = "lmdbMain",
        .root_source_file = b.path("lmdbMain.zig"),
        .target = b.graph.host,
    });

    exe.root_module.addImport("lmdbModule", lmdbModule);
    exe.linkSystemLibrary("lmdb");
    exe.linkSystemLibrary("c");

    b.installArtifact(exe);
}
