const warn = @import("std").debug.warn;
use @import("./gl.zig");
use @import("./ui.zig");

error CompileShader;
error CreateProgram;
error InitContext;
error LinkProgram;

const Attrib = struct {
    const Position = 0;
};

const positions = []f32 {
    -0.5, -0.5, 0.0,
    0.0, 0.5, 0.0,
    0.5, -0.5, 0.0,
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
        // Vertex buffers.
        enableVertexAttribArray(Attrib.Position);
        scene.position = Buffer.init(BufferTarget.Array);
        scene.position.bufferData(f32, positions[0..], Usage.StaticDraw);
        // All done.
        return scene;
    }

    pub fn deinit(self: &const Scene) void {
        self.vertex.deinit();
        self.fragment.deinit();
        self.program.deinit();
    }

    pub fn paint(self: &const Scene, window: &const Window) void {
        // TODO Get correct viewport size.
        const size = window.drawableSize();
        warn("size: [{}, {}]\n", size[0], size[1]);
        viewport(0, 0, size[0], size[1]);
        clearColor(0, 0, 0, 1);
        clear(BufferBit.Color);
        self.position.bind();
        vertexAttribPointer(
            Attrib.Position, 3, DataType.Float, u8(false), 0, bufferOffset(0),
        );
        drawArrays(DrawMode.Triangles, 0, 3);
        window.swap();
    }

};
