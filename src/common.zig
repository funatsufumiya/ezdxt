const std = @import("std");

pub const Image = struct {
    data: []const u8,
    width: u16,
    height: u16,
};

pub const Rgb565 = packed struct {
    r: u5, g: u6, b: u5,

    pub fn fromInt(int: u16) @This() {
        return .{ 
            .r = @as(u5, @truncate(int >> 11)),
            .g = @as(u6, @truncate(int >> 5)),
            .b = @as(u5, @truncate(int)),
        };
    }

    pub fn asRgba(self: @This()) Rgba {
        const maxInt = std.math.maxInt;
        return Rgba {
            .r = @as(f32, @floatFromInt(self.r)) / maxInt(u5),
            .g = @as(f32, @floatFromInt(self.g)) / maxInt(u6),
            .b = @as(f32, @floatFromInt(self.b)) / maxInt(u5),
            .a = 1,
        };
    }

    pub fn as24bit(self: @This()) Rgb888 {
        return self.asFloats().as24bit();
    }
};

pub const Rgb888 = packed struct {
    r: u8, g: u8, b: u8,
};

pub const Rgba8888 = packed struct {
    r: u8, g: u8, b: u8, a: u8,
};

pub const Rgba5654 = packed struct {
    r: u5, g: u6, b: u5, a: u4,
    _padding: u12 = undefined,
    comptime {
        std.debug.assert(@bitSizeOf(@This()) == 32);
        std.debug.assert(@sizeOf(@This()) == 4);
    }

    pub fn asRgba(self: @This()) Rgba {
        const maxInt = std.math.maxInt;
        return Rgba {
            .r = @as(f32, @floatFromInt(self.r)) / maxInt(u5),
            .g = @as(f32, @floatFromInt(self.g)) / maxInt(u6),
            .b = @as(f32, @floatFromInt(self.b)) / maxInt(u5),
            .a = @as(f32, @floatFromInt(self.a)) / maxInt(u4),
        };
    }
};

pub const Rgba = extern struct {
    r: f32, g: f32, b: f32, a: f32 = 1,

    pub const black = @This() {.r=0,.g=0,.b=0,.a=1};
    pub const transparent = @This() {
        .a = 0,
        .r = undefined, .g = undefined, .b = undefined,
    };

    pub fn assertValid(self: @This()) void {
        std.debug.assert(self.r >= 0 and self.r <= 1);
        std.debug.assert(self.g >= 0 and self.g <= 1);
        std.debug.assert(self.b >= 0 and self.b <= 1);
        std.debug.assert(self.a >= 0 and self.a <= 1);
    }

    pub fn asRgb565(self: @This()) Rgb565 {
        self.assertValid();

        const maxInt = std.math.maxInt;
        return .{
            .r = @as(u5, @intFromFloat(self.r * maxInt(u5))),
            .g = @as(u6, @intFromFloat(self.g * maxInt(u6))),
            .b = @as(u5, @intFromFloat(self.b * maxInt(u5))),
        };
    }

    // pub fn asRgba5654(self: @This()) Rgba5654 {

    // }

    pub fn asRgb888(self: @This()) Rgb888 {
        self.assertValid();

        const maxInt = std.math.maxInt;
        return .{
            .r = @as(u8, @intFromFloat(self.r * maxInt(u8))),
            .g = @as(u8, @intFromFloat(self.g * maxInt(u8))),
            .b = @as(u8, @intFromFloat(self.b * maxInt(u8))),
        };        
    }
     pub fn asRgba8888(self: @This()) Rgba8888 {
        self.assertValid();

        const maxInt = std.math.maxInt;
        return .{
            .r = @as(u8, @intFromFloat(self.r * maxInt(u8))),
            .g = @as(u8, @intFromFloat(self.g * maxInt(u8))),
            .b = @as(u8, @intFromFloat(self.b * maxInt(u8))),
            .a = @as(u8, @intFromFloat(self.a * maxInt(u8))),
        };        
    }

    pub fn mul(self: @This(), scalar: f32) @This() {
        return .{
            .r = self.r * scalar,
            .g = self.g * scalar,
            .b = self.b * scalar,
            .a = 1,
        };
    }

    pub fn div(self: @This(), scalar: f32) @This() {
        return .{
            .r = self.r / scalar,
            .g = self.g / scalar,
            .b = self.b / scalar,
            .a = 1,
        };
    }

    pub fn add(self: @This(), other: @This()) @This() {
        return .{
            .r = self.r + other.r,
            .g = self.g + other.g,
            .b = self.b + other.b,
            .a = 1,//todo: alpha blending?
        };
    }

    // exact float comparisons are bad, dont use this
    pub fn eql(self: @This(), other: @This()) bool {
        return self.r == other.r and self.g == other.g and self.b == other.b and self.a == other.a;
    }

    pub fn almostEq(self: @This(), other: @This()) bool {
        return self.approxEq(other, 0.1);
    }

    pub fn approxEq(self: @This(), other: @This(), tolerance: f32) bool {
        const aeq = std.math.approxEqAbs;
        return
            aeq(f32, self.r, other.r, tolerance) and
            aeq(f32, self.g, other.g, tolerance) and
            aeq(f32, self.b, other.b, tolerance) and
            aeq(f32, self.a, other.a, tolerance);
    }


    pub fn format(
        self: @This(),
        comptime fmt: []const u8,
        options: anytype,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;
        try writer.print(
            "RGBA ({d}, {d}, {d}, {d})",
            .{self.r, self.g, self.b, self.a}
        );
    }
};

//todo: better place for this
test "Rgb565 from int" {
    const int: u16 = 0b00100_110011_10101;
    const col = Rgb565.fromInt(int);
    const expectEqual = std.testing.expectEqual;

    try expectEqual(@as(u5, 0b00100), col.r);
    try expectEqual(@as(u6, 0b110011), col.g);
    try expectEqual(@as(u5, 0b10101), col.b);
}
