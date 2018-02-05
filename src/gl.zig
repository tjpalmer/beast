use @import("./ui.zig");
const std = @import("std");
use std.debug;
const c = @cImport({
    @cDefine("GL_GLEXT_PROTOTYPES", "");
    @cInclude("GLES3/gl3.h");
});

error CompileShader;
error CreateProgram;
error GetUniformLocation;
error InitContext;
error LinkProgram;

pub const Buffer = struct {

    buffer: c.GLuint,

    target: c.GLenum,

    pub fn init(target: c.GLenum) Buffer {
        var buffer: c.GLuint = undefined;
        c.glGenBuffers(1, &buffer);
        var buffer_struct = Buffer {.buffer = buffer, .target = target};
        buffer_struct.bind();
        return buffer_struct;
    }

    pub fn deinit(self: &const Buffer) void {
        c.glDeleteBuffers(1, &self.buffer);
    }

    pub fn bind(self: &const Buffer) void {
        c.glBindBuffer(self.target, self.buffer);
    }

    pub fn bufferData(
        self: &Buffer, comptime Item: type, data: []const Item, usage: c.GLenum,
    ) void {
        c.glBufferData(
            self.target,
            c.GLsizeiptr(data.len * @sizeOf(Item)),
            @ptrCast(?&const c.GLvoid, &data[0]),
            usage,
        );
    }

};

pub const BufferBit = struct {
    const Color = c.GL_COLOR_BUFFER_BIT;
};

pub const BufferTarget = struct {
    const Array = c.GL_ARRAY_BUFFER;
};

pub const DataType = struct {
    const Float = c.GL_FLOAT;
};

pub const DrawMode = struct {
    const Triangles = c.GL_TRIANGLES;
};

pub const Program = struct {

    program: c.GLuint,

    pub fn init() %Program {
        puts(??c.glGetString(c.GL_VERSION));
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

    fn getUniform(self: &const Program, comptime name: []const u8) %Uniform {
        const c_name = name ++ "\x00";
        const location = c.glGetUniformLocation(self.program, &c_name[0]);
        if (location < 0) {
            return error.GetUniformLocation;
        }
        return Uniform {.location = location};
    }

    fn link(self: &Program) %void {
        const program = self.program;
        c.glLinkProgram(program);
        // Check.
        var is_linked: c.GLint = 0;
        c.glGetProgramiv(program, c.GL_LINK_STATUS, &is_linked);
        if (is_linked == c.GL_FALSE) {
            var buffer = try std.Buffer.init(global_allocator, "");
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

pub const ShaderKind = struct {
    const Fragment = c.GL_FRAGMENT_SHADER;
    const Vertex = c.GL_VERTEX_SHADER;
};

pub const Uniform = struct {

    location: c.GLint,

    // TODO Define some of these in advance, including generic type?
    fn matrix4fv(
        self: &const Uniform, transpose: bool, value: []const f32,
    ) void {
        c.glUniformMatrix4fv(
            self.location, 1, c.GLboolean(transpose), &value[0],
        );
    }

};

pub const Usage = struct {
    const StaticDraw = c.GL_STATIC_DRAW;
    const StreamDraw = c.GL_STREAM_DRAW;
};

pub inline fn bufferOffset(offset: usize) &const c_void {
    return @intToPtr(&const c_void, offset);
}

pub const clear = c.glClear;
pub const clearColor = c.glClearColor;
pub const drawArrays = c.glDrawArrays;
pub const enableVertexAttribArray = c.glEnableVertexAttribArray;
pub const vertexAttribPointer = c.glVertexAttribPointer;
pub const viewport = c.glViewport;
