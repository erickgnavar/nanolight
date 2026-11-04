//! Google's answers reaching the panel, a moment after the keys that asked
//! (`suggest.pause_ms`, then the network).
const suggest = @import("suggest.zig");
const Nanolight = @import("view.zig").Nanolight;
const Row = @import("results.zig").Row;

/// Google's completions of `typed` (what `Host.suggest` asked): kept,
/// and listed if it is still what is typed. The selection stays on the
/// row it was on, wherever that row now is: Return a moment after
/// typing does what the panel showed, not a completion that just came.
pub fn answered(s: *Nanolight, typed: []const u8, said: *const suggest.List) void {
    s.cache.put(typed, said);
    if (!suggest.same(typed, s.query.text())) return;
    const was: ?Row = if (s.sel < s.res.n) s.res.rows[s.sel] else null;
    var was_text: [suggest.max_len]u8 = undefined;
    var was_len: usize = 0;
    if (was) |r| if (r.kind == .suggest) {
        const w = s.web.get(r.web);
        @memcpy(was_text[0..w.len], w);
        was_len = w.len;
    };
    s.web = said.*;
    s.fill();
    s.sel = 0;
    const r = was orelse return;
    for (s.res.slice(), 0..) |now, i| {
        const same_row = now.kind == r.kind and switch (r.kind) {
            .app, .pane => now.app == r.app,
            .file => now.file == r.file,
            .suggest => suggest.same(s.web.get(now.web), was_text[0..was_len]),
            else => true,
        };
        if (same_row) {
            s.sel = i;
            return;
        }
    }
}
