use @import("std").build;

pub fn build(builder: &Builder) %void {
  const exe = builder.addExecutable("beast", "src/main.zig");
  exe.setBuildMode(builder.standardReleaseOptions());
  builder.default_step.dependOn(&exe.step);
}
