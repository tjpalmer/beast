const std = @import("std");
use std.debug;
// use @import("std").fmt;
// use @import("std").io;
const c = @cImport({
  @cDefine("GL_GLEXT_PROTOTYPES", "");
  @cInclude("GLES3/gl32.h");
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
  c.glClearColor(0, 0, 0, 1);
  c.glClear(c.GL_COLOR_BUFFER_BIT);
  c.SDL_GL_SwapWindow(window.window);
  // const _ = c.glGetString(c.GL_VERSION);
  // puts(_);
  // warn("d\n");
  var event = c.SDL_Event {.type = 0};
  // warn("e\n");
  main: while (true) {
    while (c.SDL_PollEvent(&event) != 0) {
      if (event.type == u32(c.SDL_QUIT)) {
        break :main;
      }
    }
  }
}

// Support.

const Context = struct {

  context: c.SDL_GLContext,

  fn init(window: &const Window) %Context {
    if (c.SDL_GL_CreateContext(window.window)) |context| {
      return Context {.context = context};
    } else {
      return error.ContextInit;
    }
  }

  pub fn free(self: &const Context) void {
    c.SDL_GL_DeleteContext(self.context);
  }

};

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

error ContextInit;
error SdlError;

// Normally a macro, so we need to define it manually.
const SDL_WINDOWPOS_CENTERED: c_int = 0x2FFF0000;

const Window = struct {

  window: &c.SDL_Window,

  pub fn init() %Window {
    if (c.SDL_CreateWindow(
      c"Beast",
      SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
      800, 600,
      u32(
        // c.SDL_WINDOW_MAXIMIZED |
        c.SDL_WINDOW_OPENGL |
        c.SDL_WINDOW_RESIZABLE
      ),
    )) |window| {
      return Window {.window = window};
    } else {
      warn("Hey!\n");
      // puts(c.SDL_GetError() ?? return error.SdlError);
      return error.SdlError;
    }
  }

  pub fn free(self: &const Window) void {
    c.SDL_DestroyWindow(self.window);
  }

};

fn initGles3() %void {
  // if (c.SDL_SetHint(c.SDL_HINT_OPENGL_ES_DRIVER, c"1") == 0) {
  //   warn("won't take a hint\n");
  //   return error.SdlError;
  // }
  if (c.SDL_GL_SetAttribute(
    c.SDL_GLattr(c.SDL_GL_CONTEXT_PROFILE_MASK),
    c.SDL_GL_CONTEXT_PROFILE_ES,
  ) != 0) {
    // puts(c.SDL_GetError() ?? return error.SdlError);
    return error.SdlError;
  }
  if (c.SDL_GL_SetAttribute(
    c.SDL_GLattr(c.SDL_GL_CONTEXT_MAJOR_VERSION), 3,
  ) != 0) {
    // puts(c.SDL_GetError() ?? return error.SdlError);
    return error.SdlError;
  }
  if (c.SDL_GL_SetAttribute(
    c.SDL_GLattr(c.SDL_GL_CONTEXT_MINOR_VERSION), 2,
  ) != 0) {
    // puts(c.SDL_GetError() ?? return error.SdlError);
    return error.SdlError;
  }
}

fn puts(str: &const u8) void {
  var i: usize = 0;
  while (str[i] != 0 and i < 10) {
    warn("{}", str[i]);
  }
  warn("\n");
}
