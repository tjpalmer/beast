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

    pub fn init() %Program {
        var program = c.glCreateProgram();
        if (program == 0) return error.CreateProgram;
        return Program {.program = program};
    }

    fn deinit(self: &const Program) void {
        c.glDeleteProgram(self.program);
    }

    fn apply(self: &const Program) void {
        c.glUseProgram(self.program);
    }

    fn attach(self: &Program, shader: &const Shader) void {
        c.glAttachShader(self.program, shader.shader);
    }

    fn bindAttrib(
        self: &const Program, index: c.GLuint, comptime name: []const u8
    ) void {
        const c_name = name ++ "\x00";
        c.glBindAttribLocation(self.program, index, &c_name[0]);
    }

    fn link(self: &Program) %void {
        const program = self.program;
        c.glLinkProgram(program);
        // Check.
        var is_linked: c.GLint = 0;
        c.glGetProgramiv(program, c.GL_LINK_STATUS, &is_linked);
        if (is_linked == c.GL_FALSE) {
            var buffer = try Buffer.init(global_allocator, "");
            defer buffer.deinit();
            var length: c.GLint = 0;
            c.glGetProgramiv(program, c.GL_INFO_LOG_LENGTH, &length);
            // Given length includes the null character, so we don't need the
            // extra in the buffer.
            try buffer.resize(usize(length) - 1);
            c.glGetProgramInfoLog(program, length, &length, buffer.ptr());
            warn("{}: {}", length, buffer.toSlice());
            return error.LinkProgram;
        }
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
        scene.program = try Program.init();
        scene.program.bindAttrib(0, "position");
        scene.program.attach(scene.vertex);
        scene.program.attach(scene.fragment);
        try scene.program.link();
        scene.program.apply();
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
