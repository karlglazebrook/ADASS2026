// csubraw_f32.zig -- Zig port in f32 (2026 review variant), with the idiomatic multi-object `for` over the two
// row slices (Zig 0.11+), which asserts equal lengths once per row and needs
// no index arithmetic. Element loop; f32 (csubraw.zig uses f64).
//    zig build-exe -O ReleaseFast csubraw_f32.zig -femit-bin=csub_zig32 ; ./csub_zig32 1000 2000 10
const std = @import("std");
const Elem = f32;

fn subr(in: []const []const Elem, nx: usize, ny: usize, out: []const []Elem) void {
    _ = nx;
    for (in[0..ny], out[0..ny], 0..) |row_in, row_out, iy| {
        const fy: Elem = @floatFromInt(iy);
        for (row_in, row_out, 0..) |a, *b, ix| {
            b.* = a + (@as(Elem, @floatFromInt(ix)) + fy);
        }
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);
    var nrpt: usize = 1000;
    var nx: usize = 2000;
    var ny: usize = 10;
    if (args.len > 1) nrpt = try std.fmt.parseInt(usize, args[1], 10);
    if (args.len > 2) nx = try std.fmt.parseInt(usize, args[2], 10);
    if (args.len > 3) ny = try std.fmt.parseInt(usize, args[3], 10);
    const in = try allocator.alloc([]Elem, ny);
    const out = try allocator.alloc([]Elem, ny);
    defer {
        for (in) |row| allocator.free(row);
        for (out) |row| allocator.free(row);
        allocator.free(in);
        allocator.free(out);
    }
    for (in, out, 0..) |*row_in, *row_out, iy| {
        row_in.* = try allocator.alloc(Elem, nx);
        row_out.* = try allocator.alloc(Elem, nx);
        for (row_in.*, 0..) |*v, ix| v.* = @floatFromInt(nx - ix + ny - iy);
    }
    const stdout = std.io.getStdOut().writer();
    try stdout.print("Arrays {d} by {d} count {d}\n", .{ nx, ny, nrpt });
    for (0..nrpt) |_| subr(in, nx, ny, out);
    for (in, out, 0..) |row_in, row_out, iy| {
        for (row_in, row_out, 0..) |a, b, ix| {
            const expected = a + @as(Elem, @floatFromInt(ix)) + @as(Elem, @floatFromInt(iy));
            if (b != expected) {
                try stdout.print("Error: {d} {d} {d} {d}\n", .{ b, ix, iy, a });
                return;
            }
        }
    }
}
