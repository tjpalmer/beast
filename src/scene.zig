const warn = @import("std").debug.warn;
use @import("./gl.zig");
use @import("./transform.zig");
use @import("./ui.zig");

const Attrib = struct {
    const Position = 0;
};

const positions = []f32 {
    -0.5, -0.5, 0.0,
    0.0, 0.5, 0.0,
    0.5, -0.5, 0.0,
};

const transform = T3.init();

pub const Scene = struct {

    fragment: Shader,

    position: Buffer,

    program: Program,

    vertex: Shader,

    viewUniform: Uniform,

    pub fn init() !Scene {
        var scene = Scene {
            .fragment = undefined,
            .position = undefined,
            .program = undefined,
            .vertex = undefined,
            .viewUniform = undefined,
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
        // Uniforms.
        scene.viewUniform = try scene.program.getUniform("view");
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
        // Adjust viewport.
        const size = window.drawableSize();
        // warn("size: [{}, {}]\n", size[0], size[1]);
        viewport(0, 0, size[0], size[1]);
        const ratios = if (size[0] < size[1]) x_smaller: {
            break :x_smaller []f32{1, f32(size[0]) / f32(size[1])};
        } else y_smaller: {
            break :y_smaller []f32{f32(size[1]) / f32(size[0]), 1};
        };
        // Clear.
        clearColor(0, 0, 0, 1);
        clear(BufferBit.Color);
        // Uniforms.
        const view = []f32{
            // Just hack in a wrong transform spot for now to make sure it's
            // getting compiled in.
            // TODO Correct use of transforms.
            ratios[0], 0, 0, transform.values[0],
            0, ratios[1], 0, 0,
            0, 0, 1, 0,
            0, 0, 0, 1,
        };
        self.viewUniform.matrix4fv(true, view[0..]);
        // Draw.
        self.position.bind();
        vertexAttribPointer(
            Attrib.Position, 3, DataType.Float, u8(false), 0, bufferOffset(0),
        );
        drawArrays(DrawMode.Triangles, 0, 3);
        // Swap.
        window.swap();
    }

};
