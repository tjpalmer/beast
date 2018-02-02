const std = @import("std");
const Buffer = std.Buffer;
use std.debug;
use std.heap;
use @import("./ui.zig");
const c = @cImport({
  @cDefine("GL_GLEXT_PROTOTYPES", "");
  @cInclude("GLES3/gl3.h");
});

error CompileShader;
error CreateProgram;
error InitContext;
error LinkProgram;

pub const Program = struct {

  program: c.GLuint,

  pub fn init(shaders: []const &const Shader) %Program {
    // Create program.
    var program = c.glCreateProgram();
    if (program == 0) return error.CreateProgram;
    errdefer c.glDeleteProgram(program);
    // Link.
    for (shaders) |shader| {
      c.glAttachShader(program, shader.shader);
    }
    c.glLinkProgram(program);
    // Check.
    var is_linked: c.GLint = 0;
    c.glGetProgramiv(program, c.GL_LINK_STATUS, &is_linked);
    if (is_linked == c.GL_FALSE) {
      var buffer = try Buffer.init(global_allocator, ""); defer buffer.deinit();
      var length: c.GLint = 0;
      c.glGetProgramiv(program, c.GL_INFO_LOG_LENGTH, &length);
      // Given length includes the null character, so we don't need the extra in
      // the buffer.
      try buffer.resize(usize(length) - 1);
      c.glGetProgramInfoLog(program, length, &length, buffer.ptr());
      warn("{}: {}", length, buffer.toSlice());
      return error.LinkProgram;
    }
    return Program {.program = program};
  }

  fn deinit(self: &const Program) void {
    c.glDeleteProgram(self.program);
  }

  fn apply(self: &const Program) void {
    c.glUseProgram(self.program);
  }

  fn attrib(self: &const Program, comptime name: []const u8) c.GLint {
    const c_name = name ++ "\x00";
    return c.glGetAttribLocation(self.program, &c_name[0]);
  }

};

pub const Scene = struct {

  fragment: Shader,

  program: Program,

  vertex: Shader,

  pub fn init() %Scene {
    var scene = Scene {
      .fragment = undefined,
      .program = undefined,
      .vertex = undefined,
    };
    puts(??c.glGetString(c.GL_VERSION));
    // Create shaders.
    scene.fragment =
      try Shader.init(c.GL_FRAGMENT_SHADER, @embedFile("fragment.glsl"));
    errdefer scene.fragment.deinit();
    scene.vertex =
      try Shader.init(c.GL_VERTEX_SHADER, @embedFile("vertex.glsl"));
    errdefer scene.vertex.deinit();
    // Create and apply program.
    const shaders = []&const Shader {scene.vertex, scene.fragment};
    scene.program = try Program.init(shaders[0..]);
    scene.program.apply();
    // Attributes.
    const positionAttrib = scene.program.attrib("position");
    warn("positionAttrib: {}\n", positionAttrib);
    return scene;
  }

  pub fn deinit(self: &const Scene) void {
    self.vertex.deinit();
    self.fragment.deinit();
    self.program.deinit();
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

  fn deinit(shader: &const Shader) void {
    c.glDeleteShader(shader.shader);
  }

};

pub fn paint(window: &const Window) void {
  c.glClearColor(0, 0, 0, 1);
  c.glClear(c.GL_COLOR_BUFFER_BIT);
  window.swap();
}
