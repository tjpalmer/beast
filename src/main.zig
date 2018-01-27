use @import("std").io;

pub fn main() %void {
    var out = try getStdOut();
    try out.write("Hello, world!\n");
}
