//! The rows in view. A list longer than the panel shows whole rows from
//! `first`, and moves a whole row at a time: nothing is cut in half, nothing
//! rests between two places, and a frame is either one list or the next. A
//! scrolling box did those things (offsets between pixels, a bounce, a bar
//! that fades), each of them a frame the panel's state can't account for.
const std = @import("std");

/// One past the last row that fits in `room` from `first`.
pub fn end(heights: []const f32, first: usize, room: f32) usize {
    var used: f32 = 0;
    var i = first;
    while (i < heights.len) : (i += 1) {
        used += heights[i];
        if (used > room and i > first) return i;
    }
    return heights.len;
}

/// The furthest `first` goes: the list's last rows fill the room.
pub fn last(heights: []const f32, room: f32) usize {
    var used: f32 = 0;
    var i = heights.len;
    while (i > 0) : (i -= 1) {
        used += heights[i - 1];
        if (used > room) return i;
    }
    return 0;
}

/// `first`, moved as little as shows row `sel`.
pub fn reveal(heights: []const f32, first: usize, sel: usize, room: f32) usize {
    if (sel < first) return sel;
    var f = first;
    while (f < sel and end(heights, f, room) <= sel) f += 1;
    return f;
}

/// How far a precise wheel (a trackpad) goes for a row; a notched wheel's
/// notch comes as 12 points, and is a row.
const precise_step: f32 = 40;
const notch_step: f32 = 12;

pub const Window = struct {
    first: usize = 0,
    /// The list and the selection last shown (`update`).
    kept: u64 = 0,
    /// The wheel's points not yet a row.
    wheel: f32 = 0,

    /// Shows the selection as it or the list changes, and only then: in
    /// between, the wheel may look elsewhere. `dy` above 0 goes up the list.
    pub fn update(w: *Window, heights: []const f32, sel: usize, list: u32, room: f32, dy: f32, precise: bool) void {
        const at = @as(u64, list) << 32 | sel;
        if (at != w.kept) {
            w.kept = at;
            w.wheel = 0;
            w.first = reveal(heights, @min(w.first, last(heights, room)), sel, room);
        }
        if (dy * w.wheel < 0) w.wheel = 0;
        w.wheel += dy;
        const step = if (precise) precise_step else notch_step;
        while (w.wheel >= step) : (w.wheel -= step) w.first -|= 1;
        while (w.wheel <= -step) : (w.wheel += step) w.first += 1;
        w.first = @min(w.first, last(heights, room));
    }
};

const t = std.testing;
const eight: [12]f32 = @splat(40);

test "only whole rows are in view" {
    try t.expectEqual(@as(usize, 8), end(&eight, 0, 320));
    try t.expectEqual(@as(usize, 7), end(&eight, 0, 319));
    try t.expectEqual(@as(usize, 12), end(&eight, 4, 320));
    // A head above a row is part of it.
    try t.expectEqual(@as(usize, 2), end(&[_]f32{ 68, 40, 240 }, 0, 320));
    // A row taller than the room still shows.
    try t.expectEqual(@as(usize, 1), end(&[_]f32{ 400, 40 }, 0, 320));
}

test "the list's end fills the room, and a short list stays at the top" {
    try t.expectEqual(@as(usize, 4), last(&eight, 320));
    try t.expectEqual(@as(usize, 0), last(eight[0..3], 320));
}

test "the selection comes into view, moving as little as it can" {
    try t.expectEqual(@as(usize, 0), reveal(&eight, 0, 7, 320));
    try t.expectEqual(@as(usize, 1), reveal(&eight, 0, 8, 320));
    try t.expectEqual(@as(usize, 4), reveal(&eight, 0, 11, 320));
    try t.expectEqual(@as(usize, 2), reveal(&eight, 4, 2, 320));
}

test "the wheel moves whole rows, and leaves the selection alone until it changes" {
    var w: Window = .{};
    w.update(&eight, 0, 1, 320, 0, false);
    // A trackpad's small steps add up, and one the other way starts again.
    w.update(&eight, 0, 1, 320, -39, true);
    try t.expectEqual(@as(usize, 0), w.first);
    w.update(&eight, 0, 1, 320, 10, true);
    try t.expectEqual(@as(usize, 0), w.first);
    w.update(&eight, 0, 1, 320, -40, true);
    try t.expectEqual(@as(usize, 1), w.first);
    // A notch is a row; past the end it stops.
    w.update(&eight, 0, 1, 320, -12, false);
    try t.expectEqual(@as(usize, 2), w.first);
    w.update(&eight, 0, 1, 320, -1200, false);
    try t.expectEqual(@as(usize, 4), w.first);
    // It stays looking there, with row 0 out of view...
    w.update(&eight, 0, 1, 320, 0, false);
    try t.expectEqual(@as(usize, 4), w.first);
    // ...until the selection moves, or the list changes.
    w.update(&eight, 1, 1, 320, 0, false);
    try t.expectEqual(@as(usize, 1), w.first);
    w.update(eight[0..3], 1, 2, 320, 0, false);
    try t.expectEqual(@as(usize, 0), w.first);
}
