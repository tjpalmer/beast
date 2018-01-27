const std = @import("std");
use std.debug;
// use @import("std").fmt;
// use @import("std").io;
const c = @cImport({
  @cInclude("wchar.h");
  @cInclude("SDL.h");
});

const Sdl = struct {

  pub fn init() %Sdl {
    var sdl_version = c.SDL_version {.major = 0, .minor = 0, .patch = 0};
    c.SDL_GetVersion(&sdl_version);
    warn(
      "sdl_version {}.{}.{}\n",
      sdl_version.major, sdl_version.minor, sdl_version.patch
    );
    if (c.SDL_Init(c.SDL_INIT_VIDEO) != 0) {
      return error.SdlError;
    }
    return Sdl {};
  }

  pub fn free(self: &const Sdl) void {
    c.SDL_Quit();
  }

};

error SdlError;

// Normally a macro, so we need to define it manually.
const SDL_WINDOWPOS_CENTERED: c_int = 0x2FFF0000;

const Window = struct {

  window: &c.SDL_Window,

  pub fn init() %Window {
    var window = c.SDL_CreateWindow(
      c"Beast",
      SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
      800, 600,
      @bitCast(u32, c.SDL_WINDOW_MAXIMIZED),
    ) ?? return error.SdlError;
    return Window {.window = window};
  }

  pub fn free(self: &const Window) void {
    c.SDL_DestroyWindow(self.window);
  }

};

pub fn main() %void {
  const sdl = try Sdl.init(); defer sdl.free();
  const window = try Window.init(); defer window.free();
  var event = c.SDL_Event {.type = 0};
  main: while (true) {
    while (c.SDL_PollEvent(&event) != 0) {
      if (event.type == @bitCast(u32, c.SDL_QUIT)) {
        break :main;
      }
    }
  }
}
