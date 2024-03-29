const std = @import("std");
const print = std.debug.print;

const ai = @import("perceptron.zig");
const DataSet = ai.DataSet;
const Perceptron = ai.Perceptron;

const vec = @import("vec.zig");
const Vec = vec.Vec;

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
    var data_set = DataSet(Iris).init(allocator);
    defer data_set.deinit();

    try data_set.readFromFile(
        file,
        struct { f64, f64, f64, f64, []const u8 },
        // TODO impelement file read transformFn generic
        // .{ void, void, void, void, &fileTransformFn },
    );

    // for (data_set.points.items, 0..) |point, i| {
    //     print("{d}: {d}\n", .{ i, point });
    // }

    var perceptron = Perceptron(4, f64).init(allocator);
    perceptron.train(data_set, Iris.v, Iris.sign);
}

const Iris = struct {
    v: Vec(4, f64),
    label: []const u8,

    // TODO compare perf diff between sign fn and val
    // sign: i64,

    pub fn sign(point: Iris) i32 {
        return if (std.mem.eql(u8, point.label, "Iris-setosa")) 1 else 0;
    }
};

// fn fileTransformFn(label: []const u8) i64 {
//     return if (std.mem.eql(u8, label, "Iris-setosa")) 1 else 0;
// }
