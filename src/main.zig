const std = @import("std");
const print = std.debug.print;

const ai = @import("perceptron.zig");
const DataSet = ai.DataSet;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == std.heap.Check.ok);
    const allocator = gpa.allocator();

    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();

    _ = args.skip(); // skip file name
    const filepath = args.next().?;

    // TODO check if file if not try to read as text data

    const file = try std.fs.cwd().openFile(filepath, .{ .mode = .read_only });
    defer file.close();

    // TODO move into Layout into DataSet
    var data_set = DataSet(4, f64).init(allocator);
    defer data_set.deinit();

    try data_set.readFromFile(file, struct { f64, f64, f64, f64, []const u8 });

    for (data_set.points.items, 0..) |point, i| {
        print("{d}: {d}\n", .{ i, point });
    }
}
