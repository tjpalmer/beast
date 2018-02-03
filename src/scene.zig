use @import("./gl.zig");
use @import("./ui.zig");

error CompileShader;
error CreateProgram;
error InitContext;
error LinkProgram;

const Attrib = struct {
    const Position = 0;
};

pub const Scene = struct {

    fragment: Shader,

    position: Buffer,

    program: Program,

    vertex: Shader,

    pub fn init() %Scene {
        var scene = Scene {
            .fragment = undefined,
            .position = undefined,
            .program = undefined,
            .vertex = undefined,
        };
        // Create shaders.
        scene.fragment =
            try Shader.init(ShaderKind.Fragment, @embedFile("fragment.glsl"));
        errdefer scene.fragment.deinit();
        scene.vertex =
            try Shader.init(ShaderKind.Vertex, @embedFile("vertex.glsl"));
        errdefer scene.vertex.deinit();
        // Build program.
        scene.program = try Program.init();
        scene.program.bindAttrib(Attrib.Position, "position");
        scene.program.attach(scene.vertex);
        scene.program.attach(scene.fragment);
        // Link and apply.
        try scene.program.link();
        scene.program.apply();
        // Buffers.
        enableVertexAttribArray(Attrib.Position);
        scene.position = Buffer.init(BufferTarget.Array);
        return scene;
    }

    pub fn deinit(self: &const Scene) void {
        self.vertex.deinit();
        self.fragment.deinit();
        self.program.deinit();
    }

};

pub fn paint(window: &const Window) void {
    clearColor(0, 0, 0, 1);
    clear(BufferBit.Color);
    window.swap();
}
