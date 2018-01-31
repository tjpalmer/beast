use @import("./gfx.zig");
const std = @import("std");
use std.debug;
// use @import("std").fmt;
// use @import("std").io;
const c = @cImport({
  // See https://github.com/zig-lang/zig/issues/515
  // @cDefine("_NO_CRT_STDIO_INLINE", "1");
  @cInclude("stdio.h");
  @cDefine("GL_GLEXT_PROTOTYPES", "");
  @cInclude("GLES3/gl3.h");
  @cInclude("wchar.h");
  @cInclude("SDL.h");
});

// Main.

pub fn main() %void {
  // warn("a\n");
  const sdl = try Sdl.init(); defer sdl.free();
  // warn("b\n");
  try initGles3();
  // warn("c\n");
  const window = try Window.init(); defer window.free();
  const context = try Context.init(window); defer context.free();
  puts(c.glGetString(c.GL_VERSION) ?? return error.SdlError);
  c.glClearColor(0, 0, 0, 1);
  c.glClear(c.GL_COLOR_BUFFER_BIT);
  window.swap();
  const scene = try Scene.init(); defer scene.free();
  // warn("d\n");
  var event = c.SDL_Event {.type = 0};
  // warn("e\n");
  var done = false;
  main: while (!done) {
    while (c.SDL_PollEvent(&event) != 0) {
      switch (c_int(event.type)) {
        c.SDL_QUIT => {
          done = true;
        },
        c.SDL_WINDOWEVENT => switch (event.window.event) {
          c.SDL_WINDOWEVENT_RESIZED => {
            warn("Resize\n");
            c.glClearColor(0, 0, 0, 1);
            c.glClear(c.GL_COLOR_BUFFER_BIT);
            window.swap();
          },
          else => {}
        },
        else => {}
      }
    }
  }
}
