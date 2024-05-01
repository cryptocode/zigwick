//! This library implements Fenwick Trees (a.k.a. Binary Index Trees) in Zig
//! License: MIT

/// Construct a Fenwick type for the given numeric type. Note that this is an implicit tree, where
/// an array is used to maintain prefix sums. Sum queries and point updates are done in log(n) time.
pub fn Fenwick(comptime T: type) type {
    return struct {
        data: []T = undefined,

        /// Returns an a Fenwick tree initialized to all zeros using `buffer` as backing memory
        pub fn initZero(buffer: []T) @This() {
            var instance: @This() = .{
                .data = buffer,
            };
            instance.clear();
            return instance;
        }

        /// Given an array of numbers, produce a Fenwick tree using `buffer` as backing memory
        /// The initialization is done in O(n log(n)) time
        pub fn initFrom(buffer: []T, numbers: []T) @This() {
            var instance: @This() = .{
                .data = buffer,
            };
            instance.clear();

            var i: usize = 0;
            while (i < instance.data.len) : (i += 1) {
                instance.update(i, numbers[@intCast(i)]);
            }

            return instance;
        }

        /// Initialize all items in the tree to zero
        pub fn clear(self: *@This()) void {
            for (self.data) |*item| {
                item.* = 0;
            }
        }

        /// The cumulutative sum up to `index`
        pub fn sum(self: *@This(), index: usize) T {
            var cumulative_sum: T = 0;
            var i: isize = @intCast(index);

            // While this implements 0-based indexing, it's easier to visualize the algorithm with
            // 1-based indexing representing a tree of partial sums. Every item at an index that's a
            // power of two is the prefix sum of the [0..index] numbers. Clearing the LSB yields the
            // parent "node" in the prefix tree, which is added to the sum. The process repeats
            // until the root node is found.
            while (i >= 0) {
                cumulative_sum += self.data[@intCast(i)];
                i = (i & (i + 1)) - 1;
            }
            return cumulative_sum;
        }

        /// Returns the cumulutative sum in the range [left..right] (both indices are inclusive)
        pub fn sumRange(self: *@This(), left_index: usize, right_index: usize) T {
            return self.sum(right_index) - if (left_index > 0) self.sum(left_index - 1) else 0;
        }

        /// Add `delta` at `index`
        /// Note that `delta` can be negative for signed Ts, effectively subtracting at `index`
        pub fn update(self: *@This(), index: usize, delta: T) void {
            var i = index;
            while (i < self.data.len) : (i |= (i + 1)) {
                self.data[i] += delta;
            }
        }

        /// Return a single element's value
        pub fn get(self: *@This(), index: usize) T {
            var val: T = self.data[index];
            const i: isize = @intCast(index);
            var pow_of_two: isize = 1;
            while ((i & pow_of_two) == pow_of_two) : (pow_of_two <<= 1) {
                val -= self.data[@intCast(i - pow_of_two)];
            }

            return val;
        }

        /// Set a single element's value and recalculate prefix sums
        pub fn set(self: *@This(), index: usize, value: T) void {
            self.update(index, value - self.get(index));
        }
    };
}

const std = @import("std");
const expectEqual = std.testing.expectEqual;

/// Sum of sequence from 1 to `n`
fn gauss(n: anytype) @TypeOf(n) {
    return @divExact(n * (n + 1), 2);
}

test "update" {
    var buffer = [_]i32{0} ** 10;
    var fenwick = Fenwick(i32).initZero(&buffer);
    fenwick.update(5, 10);
    try expectEqual(fenwick.sum(5), 10);
    fenwick.update(0, 2);
    try expectEqual(fenwick.sum(5), 12);
    fenwick.update(9, 2);
    try expectEqual(fenwick.sum(9), 14);
    fenwick.update(9, -2);
    try expectEqual(fenwick.sum(9), 12);
    try expectEqual(fenwick.get(5), 10);
    fenwick.set(5, 9);
    try expectEqual(fenwick.get(5), 9);
    try expectEqual(fenwick.sum(9), 11);
}

test "set" {
    const N = 50;
    var buffer = [_]i32{0} ** N;
    var fenwick = Fenwick(i32).initZero(&buffer);

    var i: i32 = 0;
    while (i < N) : (i += 1) {
        fenwick.set(@intCast(i), i + 1);
    }

    i = 0;
    while (i < N) : (i += 1) {
        fenwick.set(@intCast(i), i + 1);
    }
    try expectEqual(fenwick.sum(N - 1), gauss(N));

    i = 0;
    while (i < N) : (i += 1) {
        try expectEqual(fenwick.get(@intCast(i)), i + 1);
    }
}

test "empty" {
    var data: [0]i32 = .{};
    var buffer = [_]i32{0} ** 0;
    var fenwick = Fenwick(i32).initFrom(&buffer, &data);
    fenwick.clear();
}

test "array with negative culumative sums" {
    var data: [5]i32 = .{ -1, -5, -1, 0, 5 };
    var buffer = [_]i32{0} ** 5;
    var fenwick = Fenwick(i32).initFrom(&buffer, &data);
    try expectEqual(fenwick.sum(0), -1);
    try expectEqual(fenwick.sum(4), -2);
    try expectEqual(fenwick.sum(1), -6);
    try expectEqual(fenwick.sumRange(0, 1), -6);
    try expectEqual(fenwick.sumRange(1, 2), -6);
    try expectEqual(fenwick.sumRange(0, 4), -2);
    try expectEqual(fenwick.sumRange(4, 4), 5);
    fenwick.clear();
    try expectEqual(fenwick.sumRange(0, 4), 0);
}

test "range backwards" {
    var data: [5]u16 = .{ 5, 4, 3, 2, 1 };
    var buffer = [_]u16{0} ** 5;
    var fenwick = Fenwick(u16).initFrom(&buffer, &data);
    try expectEqual(fenwick.sum(4), 15);
    try expectEqual(fenwick.sum(3), 14);
    try expectEqual(fenwick.sum(2), 12);
    try expectEqual(fenwick.sum(1), 9);
    try expectEqual(fenwick.sum(0), 5);
}

test "range floats" {
    var data: [5]f16 = .{ 1.5, 2.5, 3.5, 4.5, 5.5 };
    var buffer = [_]f16{0} ** 5;
    var fenwick = Fenwick(f16).initFrom(&buffer, &data);
    try expectEqual(fenwick.sum(4), 17.5);
    try expectEqual(fenwick.sum(3), 12);
    try expectEqual(fenwick.sum(2), 7.5);
    try expectEqual(fenwick.sum(1), 4);
    try expectEqual(fenwick.sum(0), 1.5);
}

test "larger range" {
    var data: [264]u16 = .{
        1,  2,  3,  4,  5,  6,  7,  8,  9,  10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32,
        33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64,
        65, 66, 1,  2,  3,  4,  5,  6,  7,  8,  9,  10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30,
        31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62,
        63, 64, 65, 66, 1,  2,  3,  4,  5,  6,  7,  8,  9,  10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28,
        29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60,
        61, 62, 63, 64, 65, 66, 1,  2,  3,  4,  5,  6,  7,  8,  9,  10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26,
        27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58,
        59, 60, 61, 62, 63, 64, 65, 66,
    };
    var buffer = [_]u16{0} ** (264);
    var fenwick = Fenwick(u16).initFrom(&buffer, &data);

    try expectEqual(fenwick.sum(0), 1);
    try expectEqual(fenwick.sum(263), 8844);
    try expectEqual(fenwick.sum(262), 8844 - 66);
    try expectEqual(fenwick.sumRange(1, 263), 8843);
    try expectEqual(fenwick.sumRange(10, 12), 36);
    try expectEqual(fenwick.sumRange(82, 129), 1944);
    try expectEqual(fenwick.sumRange(82, 83), 17 + 18);
}
