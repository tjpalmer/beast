const builtin = @import("builtin");
use @import("std").build;

pub fn build(builder: &Builder) void {
  const exe = builder.addExecutable("beast", "src/main.zig");
  exe.setBuildMode(builder.standardReleaseOptions());
  if (false) {
    exe.setTarget(
      builtin.Arch.wasm32, builtin.Os.freestanding, builtin.Environ.unknown,
    );
  }
  exe.linkSystemLibrary("c");
  exe.linkSystemLibrary("libEGL.lib");
  exe.linkSystemLibrary("libGLESv2.lib");
  exe.linkSystemLibrary("SDL2.lib");
  builder.default_step.dependOn(&exe.step);
  // ANGLE.
  builder.addCIncludePath("import/angle/include");
  builder.addLibPath("import/angle/lib/x64");
  // SDL.
  builder.addCIncludePath("import/sdl2/include");
  builder.addLibPath("import/sdl2/lib/x64");
  // try builder.copyFile("import/sdl2/lib/x64/SDL2.dll", "zig-cache");
}
