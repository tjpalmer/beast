const std = @import("std");
use std.debug;
// use @import("std").fmt;
// use @import("std").io;
const c = @cImport({
  @cInclude("wchar.h");
  @cInclude("SDL.h");
});

pub fn main() %void {
  // var out = try getStdOut();
  // try out.write("Hello, world!!\n");
  // const _ = c.SDL_Init(c.SDL_INIT_VIDEO | c.SDL_INIT_AUDIO);
  var sdl_version = c.SDL_version {.major = 0, .minor = 0, .patch = 0};
  c.SDL_GetVersion(&sdl_version);
  // try format(out, out.write, "");
  // try out.write(version.major);
  warn(
    "sdl_version {}.{}.{}\n",
    sdl_version.major, sdl_version.minor, sdl_version.patch
  );
}
