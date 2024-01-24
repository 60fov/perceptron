const std = @import("std");

const vec = @import("vec.zig");
const Vec = vec.Vec;
const VecType = vec.VecType;

const print = std.debug.print;

// TODO
// check to see if current error is stack overflow
// ideal: use debugger and visualize stack

// NOTE do i need to store the allocator?
pub fn DataSet(comptime T: type) type {
    return struct {
        const Self = @This();

        allocator: std.mem.Allocator,
        // TODO multi array list
        points: std.ArrayList(T),
        dsr: Reader(T),

        pub fn init(allocator: std.mem.Allocator) Self {
            return .{
                .allocator = allocator,
                .points = std.ArrayList(T).init(allocator),
                .dsr = Reader(T){},
            };
        }

        pub fn deinit(this: *Self) void {
            this.points.deinit();
        }

        pub fn readFromFile(
            this: *Self,
            file: std.fs.File,
            comptime Layout: type,
            // comptime transforms: anytype,
        ) !void {
            // TODO

            const reader = file.reader();
            while (try reader.readUntilDelimiterOrEofAlloc(this.allocator, '\n', 4096)) |line| {
                defer this.allocator.free(line);
                if (line.len < 1) continue;
                const data_point = try this.parseCSV(line, Layout);
                try this.points.append(data_point);
            }
        }

        pub fn parseCSV(this: *Self, s: []const u8, Layout: anytype) !T {
            defer this.dsr.clear();

            var tokens = std.mem.tokenizeAny(u8, s, ",");
            const fields = std.meta.fields(Layout);

            inline for (fields) |field| {
                const token = tokens.next();
                // print("field: {}\t token: {s}\n", .{ field.type, token.? });
                switch (field.type) {
                    f64, i64, []const u8 => try this.dsr.read(field.type, token.?),
                    void => continue,
                    else => return error.UnhandledParamType,
                }
            }

            const data = this.dsr.data[0..];
            // TODO look at this
            return @as(*T, @alignCast(@ptrCast(data))).*;
        }
    };
}

// TODO rename
fn Reader(comptime T: type) type {
    return struct {
        const Self = @This();

        // TODO consider making slice and initializing with allocator
        data: [@sizeOf(T)]u8 = [_]u8{0} ** @sizeOf(T),
        offset: usize = 0,

        pub fn read(this: *Self, comptime DataType: type, s: []const u8) !void {
            const size = @sizeOf(DataType);
            const start = this.offset;

            this.data[start..][0..size].* = switch (DataType) {
                f64 => @bitCast(try std.fmt.parseFloat(f64, s)),
                i64 => @bitCast(try std.fmt.parseInt(i64, s)),
                []const u8 => std.mem.toBytes(s), // TODO fix?
                else => return error.UnhandledParamType,
            };

            this.offset += size;
        }

        pub fn clear(this: *Self) void {
            this.offset = 0;
            this.data = [_]u8{0} ** @sizeOf(T);
        }
    };
}

pub fn Perceptron(comptime T: type, comptime dim: comptime_int) type {
    return struct {
        const Self = @This();

        allocator: std.mem.Allocator,
        w: [dim]T,
        rate: f64,

        pub fn init(allocator: std.mem.Allocator) Perceptron() {
            return Self{
                .allocator = allocator,
                .w = [_]f64{0} ** dim,
            };
        }

        pub fn train(this: *Self, data_set: DataSet(T), vector_field: anytype, sign: anytype) void {
            _ = this;

            // TODO handle vector field
            _ = vector_field;

            for (data_set.points) |point| {
                const s = switch (@TypeOf(sign)) {
                    fn (data_point: T) i8 => sign(point),
                    // TODO range of bits?
                    std.meta.Int(.Signed, 8) => sign,
                    else => @compileError(""),
                };
                _ = s;

                // const d = Vec.dot(T, dim, this.w, point.v);
                // this.w = Vec.add(T, dim, this.w, point.v);
            }
        }
    };
}
