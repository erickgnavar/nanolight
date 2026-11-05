//! What the Settings screen (settings_view.zig) asks of the app: the
//! shortcut, opening at login, updates. Optional,
//! like the panel's other host callbacks: tests, the film and the promo
//! draw Settings with defaults and call nothing.
const shortcut = @import("shortcut.zig");
const Theme = @import("palette.zig").Theme;

pub const SettingsHost = struct {
    ctx: *anyopaque,
    choice: *const fn (ctx: *anyopaque) shortcut.Choice,
    apply: *const fn (ctx: *anyopaque, c: shortcut.Choice) void,
    /// Starts or stops recording a key of one's own: the keys pressed go
    /// to `Settings.took`, not the panel (recorder.zig).
    record: *const fn (ctx: *anyopaque, on: bool) void,
    /// Whether it opens at login; `set` changes it first.
    login: *const fn (ctx: *anyopaque, set: ?bool) bool,
    /// Google's suggestions turned on or off in Settings.
    suggest: *const fn (ctx: *anyopaque, on: bool) void,
    /// Return sends Google searches to the browser (on) or the panel.
    searches_out: *const fn (ctx: *anyopaque, on: bool) void,
    /// The panel's tint, chosen in Settings: kept for the next launch.
    theme: *const fn (ctx: *anyopaque, t: Theme) void,
    /// Whether the menu bar icon shows; `set` changes it first.
    menu_bar: *const fn (ctx: *anyopaque, set: ?bool) bool,
    /// The version running, and a newer one waiting (else null).
    version: *const fn (ctx: *anyopaque) []const u8,
    ready: *const fn (ctx: *anyopaque) ?[]const u8,
    check: *const fn (ctx: *anyopaque) void,
    restart: *const fn (ctx: *anyopaque) void,
    welcome: *const fn (ctx: *anyopaque) void,
    quit: *const fn (ctx: *anyopaque) void,
};
