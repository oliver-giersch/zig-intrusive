//! Inspired by (ported from freebsd/sys/sys/tree.h)

const std = @import("std");
const math = std.math;

pub fn RBTree(comptime T: type, comptime field_name: []const u8, comptime cmp: fn (*T, *T) math.Order) type {
    return struct {
        const Self = @This();

        pub const Entry = struct {
            parent: ?*Self.Entry,
            left: ?*Self.Entry,
            right: ?*Self.Entry,

            fn init(self: *Self.Entry, parent: ?*Self.Entry) void {
                self.parent = parent;
                self.left = null;
                self.right = null;
            }

            fn getPrev(self: *Self.Entry) ?*Self.Entry {
                var curr = self;
                if (curr.left) |left| {
                    curr = left;
                    while (curr.right) |right| {
                        curr = right;
                    }

                    return curr;
                } else {
                    while (curr.parent) |parent| {
                        if (curr != parent.left) {
                            break;
                        }

                        curr = parent;
                    }

                    return curr.parent;
                }
            }
        };

        root: ?*Self.Entry,

        pub fn insert(self: *Self, item: *Self.Entry) ?*Self.Entry {
            var prev = &self.root;
            var parent = null;

            while (prev.*) |curr| {
                parent = curr;
                switch (cmp(item, entryToParent(curr))) {
                    .lt => prev = &curr.left,
                    .gt => prev = &curr.right,
                    else => return parent,
                }
            }

            return self.insertFinish(parent, prev, item);
        }

        fn insertFinish(self: *Self, parent: ?*Self.Entry, prev: *?*Self.Entry, item: *T) ?*Self.Entry {
            const item_entry = &@field(item, field_name);

            item_entry.init(parent);
            prev.* = item_entry;

            if (parent) |_| {
                @panic("self.insertColor(parent, item_entry)");
            }

            @panic("entry.augmentWalk(...)");

            _ = self;
            @panic("TODO");
        }

        fn entryToParent(_: *Self.Entry) *T {
            @panic("todo");
        }
    };
}
