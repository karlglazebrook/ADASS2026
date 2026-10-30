// csubraw.zig — Zig port of csubraw.py / csubraw.rb / csubraw.cr.
//
// Zig competes directly with C: manual memory management, no hidden
// control flow, AOT compilation via LLVM.  This benchmark gives us a
// direct C-vs-Zig comparison on the same hardware and same compiler
// backend (both are LLVM IR -> arm64).

const std = @import("std");

fn subr(in: [][]f64, nx: usize, ny: usize, out: [][]f64) void {
    var iy: usize = 0;
    while (iy < ny) : (iy += 1) {
        const row_in = in[iy];
        const row_out = out[iy];
        var ix: usize = 0;
        while (ix < nx) : (ix += 1) {
            row_out[ix] = row_in[ix] +
                @as(f64, @floatFromInt(ix)) +
                @as(f64, @floatFromInt(iy));
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
    if (args.len > 2) nx   = try std.fmt.parseInt(usize, args[2], 10);
    if (args.len > 3) ny   = try std.fmt.parseInt(usize, args[3], 10);

    const in  = try allocator.alloc([]f64, ny);
    const out = try allocator.alloc([]f64, ny);
    defer {
        for (in)  |row| allocator.free(row);
        for (out) |row| allocator.free(row);
        allocator.free(in);
        allocator.free(out);
    }
    var iy: usize = 0;
    while (iy < ny) : (iy += 1) {
        in[iy]  = try allocator.alloc(f64, nx);
        out[iy] = try allocator.alloc(f64, nx);
        var ix: usize = 0;
        while (ix < nx) : (ix += 1) {
            in[iy][ix] = @as(f64, @floatFromInt(nx - ix + ny - iy));
        }
    }

    const stdout = std.io.getStdOut().writer();
    try stdout.print("Arrays {d} by {d} count {d}\n", .{ nx, ny, nrpt });

    var r: usize = 0;
    while (r < nrpt) : (r += 1) subr(in, nx, ny, out);

    iy = 0;
    while (iy < ny) : (iy += 1) {
        var ix: usize = 0;
        while (ix < nx) : (ix += 1) {
            const expected = in[iy][ix] +
                @as(f64, @floatFromInt(ix)) +
                @as(f64, @floatFromInt(iy));
            if (out[iy][ix] != expected) {
                try stdout.print("Error: {d} {d} {d} {d}\n",
                    .{ out[iy][ix], ix, iy, in[iy][ix] });
                return;
            }
        }
    }
}
