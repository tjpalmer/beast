use @import("std").debug;
use @import("./ui.zig");
const c = @cImport({
  @cDefine("GL_GLEXT_PROTOTYPES", "");
  @cInclude("GLES3/gl3.h");
});

error CompileShader;
error CreateProgram;
error InitContext;

pub const Scene = struct {

  vertex: Shader,

  pub fn init() %Scene {
    puts(c.glGetString(c.GL_VERSION) ?? return error.SdlError);
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

pub fn paint(window: &const Window) void {
  c.glClearColor(0, 0, 0, 1);
  c.glClear(c.GL_COLOR_BUFFER_BIT);
  window.swap();
}
