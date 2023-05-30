//! Inspired by (ported from freebsd/sys/sys/queue.h)

const std = @import("std");
const mem = std.mem;

const intrusive = @This();

pub fn SQueue(comptime T: type, comptime field_name: []const u8) type {
    return struct {
        const Self = @This();

        comptime {
            assertHasField(T, field_name, Self.Entry);
        }

        const entry_offset = @offsetOf(T, field_name);

        pub const Entry = SEntry;

        /// The head entry pointer.
        head: ?*Self.Entry,
        /// The pointer to the tail entry pointer.
        ///
        /// We store an always valid pointer here to avoid a null check in many
        /// queue operations.
        /// Initially, i.e., for an empty queue, this is a self-referential
        /// pointer the queue's own `head` member variable.
        /// Consequently, it is never safe to move or copy a queue instance and
        /// queues may only be used in-place.
        tail: *?*Self.Entry,

        pub fn init(self: *Self) void {
            self.head = null;
            self.tail = &self.head;
        }

        pub fn insertTail(self: *Self, item: *T) void {
            intrusive.sQueueInsertTail(&self.tail, @ptrCast(*anyopaque, item), entry_offset);
        }

        pub fn removeTail(self: *Self) ?*T {
            return intrusive.sQueueRemoveTail(&self.tail, entry_offset);
        }

        pub fn removeHead(self: *Self) ?*T {
            return intrusive.sQueueRemoveHead(&self.head, &self.tail, entry_offset);
        }
    };
}

pub fn SList(comptime T: type, comptime field_name: []const u8) type {
    return struct {
        const Self = @This();

        comptime {
            assertHasField(T, field_name, Self.Entry);
        }

        const entry_offset = @offsetOf(T, field_name);

        pub const Entry = SEntry;

        head: ?*Self.Entry,

        pub fn insertHead(self: *Self, item: *T) void {
            intrusive.sListInsertAfter(
                &self.head,
                @ptrCast(*anyopaque, item),
                entry_offset,
            );
        }

        pub fn insertAfter(self: *Self, entry: *Self.Entry, item: *T) void {
            _ = self;
            intrusive.sListInsertAfter(&entry.next, @ptrCast(*anyopaque, item), entry_offset);
        }

        pub fn removeHead(self: *Self) ?*T {
            return intrusive.sListRemoveHead(&self.head, entry_offset);
        }
    };
}

const SEntry = struct {
    next: ?*SEntry = null,
};

fn sQueueRemoveHead(head: *?*SEntry, tail: **?*SEntry, offset: usize) ?*anyopaque {
    const ptr = head.* orelse return null;
    head.* = ptr.next;
    if (head.* == null) {
        tail.* = head;
    }

    return sEntryToItem(ptr, offset);
}

fn sQueueInsertTail(tail: **?*SEntry, item: *anyopaque, offset: usize) void {
    const item_entry = itemToSEntry(item, offset);
    tail.*.* = item_entry;
    tail.* = item_entry;
}

fn sQueueRemoveTail(tail: **?*SEntry, offset: usize) ?*anyopaque {
    const ptr = tail.*.* orelse return null;
    tail.* = null;
    return sEntryToItem(ptr, offset);
}

fn sListRemoveHead(head: *?*SEntry, offset: usize) ?*anyopaque {
    const ptr = head.* orelse return null;
    head.* = ptr.next;
    return sEntryToItem(ptr, offset);
}

fn sListInsertAfter(entry: *?*SEntry, item: *anyopaque, offset: usize) void {
    const item_entry = itemToSEntry(item, offset);
    item_entry.next = entry.*;
    entry.* = item_entry;
}

inline fn itemToSEntry(item: *anyopaque, offset: usize) *SEntry {
    return @intToPtr(*SEntry, (@ptrToInt(item) + offset));
}

inline fn sEntryToItem(entry: *SEntry, offset: usize) *anyopaque {
    return @intToPtr(*anyopaque, (@ptrToInt(entry) - offset));
}

const DEntry = struct {
    prev: ?*DEntry = null,
    next: ?*DEntry = null,
};

inline fn itemToDEntry(item: *anyopaque, offset: usize) *DEntry {
    return @intToPtr(*DEntry, (@ptrToInt(item) + offset));
}

fn assertHasField(comptime T: type, comptime field_name: []const u8, comptime field_type: type) void {
    const err_msg = "list/queue entry type requires a field '" ++ field_name ++ "'";
    const fields = switch (@typeInfo(T)) {
        .Struct => |s| s.fields,
        else => @compileError(err_msg),
    };

    inline for (fields) |field| {
        if (mem.eql(u8, field.name, field_name) and field.field_type == field_type) return;
    }

    @compileError(err_msg);
}
