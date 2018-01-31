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

error CompileShader;
error CreateProgram;
error InitContext;
error SdlError;

pub const Context = struct {

  context: c.SDL_GLContext,

  fn init(window: &const Window) %Context {
    if (c.SDL_GL_CreateContext(window.window)) |context| {
      return Context {.context = context};
    } else {
      puts(c.SDL_GetError() ?? return error.SdlError);
      return error.InitContext;
    }
  }

  pub fn free(self: &const Context) void {
    c.SDL_GL_DeleteContext(self.context);
  }

};

pub const Scene = struct {

  vertex: Shader,

  pub fn init() %Scene {
    var program = c.glCreateProgram();
    if (program == 0) return error.CreateProgram;
    return Scene {
      .vertex = try Shader.init(c.GL_VERTEX_SHADER, @embedFile("vertex.glsl")),
    };
  }

  pub fn free(self: &const Scene) void {
    self.vertex.free();
  }

};

pub const Sdl = struct {

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

pub const Shader = struct {

  shader: c.GLuint,

  fn init(shader_type: c_uint, source: []const u8) %Shader {
    // Create.
    var shader = c.glCreateShader(shader_type);
    // Compile.
    const sources: ?&const u8 = &source[0];
    const sizes = c.GLint(source.len);
    c.glShaderSource(shader, 1, &sources, &sizes);
    c.glCompileShader(shader);
    // Check.
    var is_compiled: c.GLint = 0;
    c.glGetShaderiv(shader, c.GL_COMPILE_STATUS, &is_compiled);
    if (is_compiled == 0) return error.CompileShader;
    // console.log(source);
    // console.log(gl.getShaderInfoLog(shader));
    // All done.
    return Shader {.shader = shader};
  }

  fn free(shader: &const Shader) void {
    c.glDeleteShader(shader.shader);
  }

};

// Normally a macro, so we need to define it manually.
const SDL_WINDOWPOS_CENTERED: c_int = 0x2FFF0000;

pub const Window = struct {

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

  pub fn swap(self: &const Window) void {
    c.SDL_GL_SwapWindow(self.window);
  }

};

pub fn initGles3() %void {
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
  // ANGLE doesn't claim to support 3.1 yet on desktop gl, but asking for 3.0
  // here also fails for me at the moment, so just don't say.
  // if (c.SDL_GL_SetAttribute(
  //   c.SDL_GLattr(c.SDL_GL_CONTEXT_MINOR_VERSION), 1,
  // ) != 0) {
  //   // puts(c.SDL_GetError() ?? return error.SdlError);
  //   return error.SdlError;
  // }
}

pub fn puts(str: &const u8) void {
  // Ignoring result for now, since this is low priority here.
  const _ = c.puts(str);
  // const _ = c.printf(c"%s\n", str);
  // c.fflush(c.stdout);
}
