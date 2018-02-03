use @import("./scene.zig");
use @import("./ui.zig");
use @import("std").debug;
const c = @cImport({
    @cInclude("wchar.h");
    @cInclude("SDL.h");
});

// Main.

pub fn main() %void {
    // warn("a\n");
    const sdl = try Sdl.init(); defer sdl.deinit();
    // warn("b\n");
    try initGles3();
    // warn("c\n");
    const window = try Window.init(); defer window.deinit();
    const context = try Context.init(window); defer context.deinit();
    const scene = try Scene.init(); defer scene.deinit();
    scene.paint(window);
    // warn("d\n");
    var event = c.SDL_Event {.type = 0};
    // warn("e\n");
    var done = false;
    main: while (!done) {
        while (c.SDL_PollEvent(&event) != 0) {
            switch (c_int(event.type)) {
                c.SDL_QUIT => {
                    done = true;
                },
                c.SDL_WINDOWEVENT => switch (event.window.event) {
                    c.SDL_WINDOWEVENT_RESIZED => {
                        warn("Resize\n");
                        scene.paint(window);
                    },
                    else => {}
                },
                else => {}
            }
        }
    }
}
