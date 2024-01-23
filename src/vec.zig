const std = @import("std");
const print = std.debug.print;

pub fn VecType(comptime dim: comptime_int, comptime T: type) type {
    return struct {
        const Self = @This();
        const VecImpl = Vec(dim, T);
        const Vector = @Vector(dim, T);
        const Array = [dim]T;
        const Scalar = T;

        // TODO slice support?
        // const Slice = []T;

        // TODO expose these?
        // NOTE zls doesn't do these right, suggests SomeVecType.dim rather than SomeVecType.Dim
        const Type = T;
        const Dim = dim;

        pub fn mulArray(a: [dim]T, b: [dim]T) Vector {
            const result: @Vector(dim, T) = .{};
            for (0..dim) |i| {
                result[i] = a[i] * b[i];
            }
            return result;
        }

        pub fn dotArray(a: [dim]T, b: [dim]T) T {
            var result: T = 0;
            for (0..dim) |i| {
                result += a[i] * b[i];
            }
            return result;
        }

        pub fn dot(a: anytype, b: anytype) T {
            switch (@TypeOf(a)) {
                VecImpl => {
                    return switch (@TypeOf(b)) {
                        VecImpl => @reduce(.Add, a.v * b.v),
                        Vector, Array => @reduce(.Add, a.v * b),
                        else => @compileError("invalid typeof for Vec operation, b: " ++ @TypeOf(b)),
                    };
                },
                Vector => {
                    return switch (@TypeOf(b)) {
                        VecImpl => @reduce(.Add, a * b.v),
                        Vector, Array => @reduce(.Add, a * b),
                        else => @compileError("invalid typeof for Vec operation, b: " ++ @TypeOf(b)),
                    };
                },
                Array => {
                    return switch (@TypeOf(b)) {
                        VecImpl => @reduce(.Add, a * b.v),
                        Vector => @reduce(.Add, a * b),
                        Array => dotArray(a, b),
                        else => @compileError("invalid typeof for Vec operation, b: " ++ @typeName(@TypeOf(b))),
                    };
                },
                else => @compileError("invalid typeof for Vec operation, a: " ++ @typeName(@TypeOf(a))),
            }
        }

        pub fn mul(a: anytype, b: anytype) Vector {
            switch (@TypeOf(a)) {
                VecImpl => {
                    return switch (@TypeOf(b)) {
                        VecImpl => a.v * b.v,
                        Vector, Array => a.v * b,
                        // NOTE zls zig de-sync (both 0.11.0)
                        // zls: @splat(len, scalar)
                        // zig: @splat(scalar)
                        Scalar => a.v * @as(@Vector(dim, T), @splat(b)),
                        else => @compileError("invalid typeof for Vec operation, b: " ++ @typeName(@TypeOf(b))),
                    };
                },
                Vector => {
                    return switch (@TypeOf(b)) {
                        VecImpl => a * b.v,
                        Vector, Array => a * b,
                        Scalar => a * @as(@Vector(dim, T), @splat(b)),
                        else => @compileError("invalid typeof for Vec operation, b: " ++ @typeName(@TypeOf(b))),
                    };
                },
                Array => {
                    return switch (@TypeOf(b)) {
                        VecImpl => a * b.v,
                        Vector => a * b,
                        Array => mulArray(a, b),
                        Scalar => a * @as(@Vector(dim, T), @splat(b)),
                        else => @compileError("invalid typeof for Vec operation, b: " ++ @typeName(@TypeOf(b))),
                    };
                },
                Scalar => {
                    @compileLog("[warn] put scalar after vec");
                    return Self.mul(b, a);
                    // TODO consider allowing
                    // return switch (@TypeOf(b)) {
                    //     VecImpl => @as(@Vector(dim, T), @splat(a)) * b.v,
                    //     Vector => @as(@Vector(dim, T), @splat(a)) * b,
                    //     Array => @as(@Vector(dim, T), @splat(a)) * b,
                    //     Scalar => @compileError("just multiply silly, " ++ @typeName(@TypeOf(a)) ++ " * " ++ @typeName(@TypeOf(b))),
                    //     else => @compileError("invalid typeof for Vec operation, b: " ++ @typeName(@TypeOf(b))),
                    // };
                },
                else => {
                    @compileError("invalid typeof for Vec operation, a: " ++ @TypeOf(a));
                },
            }
        }
    };
}

pub fn Vec(comptime dim: comptime_int, comptime T: type) type {
    return struct {
        const Self = @This();
        const V = VecType(dim, T);

        // TODO consider renaming
        v: @Vector(dim, T) = [_]T{0} ** dim,

        pub fn dot(this: *Self, v: anytype) T {
            return V.dot(this.*, v);
            // TODO check if this perfs better
            // if so implement type checks
            // return @reduce(.Add, this.v * v);
        }

        pub fn mul(this: *Self, v: anytype) void {
            this.v = V.mul(this, v);
            // TODO check if compiler optimizes
            // if so implement type checks
            // this.v *= v;
        }

        // TODO
        pub fn add(this: *Self, v: anytype) void {
            _ = v;
            _ = this;
        }
    };
}

const expectEqual = std.testing.expectEqual;

// TODO write tests lol

test "vector base functions" {}

test "vector general functions" {}

test "vector implicit functions" {
    var vec = Vec(4, f64){ .v = [_]f64{ 0, 1, 2, 3 } };

    try expectEqual(vec.dot(vec), @reduce(.Add, vec.v * vec.v));
    try expectEqual(Vec(4, f64).dot(&vec, vec.v), @reduce(.Add, vec.v * vec.v));

    // vec.set([_]f64{ 0, 1, 2, 3 });
    // vec.zero();
    // vec.unit();
    // vec.mul();
    // vec.len();
    // vec.len2();

}

test "Vectors" {
    var v1 = @Vector(4, f64){ 0, 1, 2, 3 };
    var v2 = @Vector(4, f64){ 4, 4, 4, 4 };

    var v3: [4]f64 = v1;
    var v3_ptr = &v3;

    var v4 = [_]f64{ 0, 1, 2, 3 };

    const V4f = VecType(4, f64);
    try expectEqual(V4f.Type, f64);
    // try expectEqual(V4f.dim, 4);

    var vec = Vec(4, f64){ .v = [_]f64{ 0, 1, 2, 3 } };
    try expectEqual(V4f.dot(vec, vec), @reduce(.Add, vec.v * vec.v));

    try expectEqual(@reduce(.Add, v1 * v2), V4f.dot(v1, v2));
    try expectEqual(@reduce(.Add, v2 * v1), V4f.dot(v1, v2));
    try expectEqual(@reduce(.Add, v1 * v2), V4f.dot(v3, v2));
    try expectEqual(@reduce(.Add, v1 * v2), V4f.dot(v3_ptr.*, v2));
    try expectEqual(v4 * v2, v1 * v2);
}
