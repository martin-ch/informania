const std = @import("std");

pub fn build(b: *std.Build) void {
    const lmdbModule = b.createModule(.{
        .root_source_file = b.path("lmdbModule.zig"),
    });

    // const natsModule = b.createModule(.{
    //     .root_source_file = b.path("natsModule.zig"),
    // });

    const exe = b.addExecutable(.{
        .name = "Main",
        .root_source_file = b.path("Main.zig"),
        .target = b.graph.host,
    });

    exe.root_module.addImport("lmdbModule", lmdbModule);
    // exe.root_module.addImport("natsModule", natsModule);
    // natsModule.addImport("lmdbModule", lmdbModule);
    // exe.addLibraryPath(.{ .cwd_relative = "/opt/vcpkg/installed/x64-linux/lib" });
    exe.linkSystemLibrary("c");
    exe.linkSystemLibrary("lmdb");
    // exe.linkSystemLibrary("nats_static");
    // exe.linkSystemLibrary("ssl");
    // exe.linkSystemLibrary("crypto");
    // exe.linkSystemLibrary("sodium");

    b.installArtifact(exe);
}
