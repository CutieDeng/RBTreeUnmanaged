const std = @import("std");

const r = @import("r"); 

pub fn main() !void {
    const R = r.RBTreeUnmanaged; 
    const T = R(i64, std.math.order); 
    const T2 = r.ArrayRedBlackTree(T); 
    var t = T2.init(std.heap.c_allocator); 
    defer t.deinit(); 
    const stdin = std.io.getStdIn(); 
    if (!stdin.isTty()) {
        std.log.info("Stdin is not a terminal. ", .{}); 
        return ; 
    }
    const reader = stdin.reader(); 
    const writer = std.io.getStdOut().writer(); 
    while (true) {
        const rl = try reader.readUntilDelimiterAlloc(std.heap.c_allocator, '\n', 80); 
        defer std.heap.c_allocator.free(rl); 
        if (std.mem.startsWith(u8, rl, "QUERY ")) {
            const less = rl[6..]; 
            const q = std.fmt.parseInt(i64, less, 10) catch {
                std.log.warn("Invalid int '{s}'", .{ less }); 
                continue; 
            }; 
            const e = t.exists(q);
            if (e) {
                try writer.print("{d} is in the struct. \n", .{ q }); 
            } else {
                try writer.print("{d} isn't in the struct. \n", .{ q }); 
            }
        } else if (std.mem.startsWith(u8, rl, "ADD ")) {
            const less = rl[4..]; 
            const q = std.fmt.parseInt(i64, less, 10) catch {
                std.log.warn("Invalid int '{s}'", .{ less }); 
                continue; 
            }; 
            const a = try t.append(q); 
            if (a) {
                try writer.print("add success. \n", .{ }); 
            } else {
                try writer.print("add fails, cause: {d} exist. \n", .{ q }); 
            }
        } else if (std.mem.startsWith(u8, rl, "RM ")) {
            const less = rl[3..]; 
            const q = std.fmt.parseInt(i64, less, 10) catch {
                std.log.warn("Invalid int '{s}'", .{ less }); 
                continue; 
            }; 
            const a = t.remove(q); 
            if (a) {
                try writer.print("remove success. \n", .{ }); 
            } else {
                try writer.print("remove fails, cause: {d} not exist. \n", .{ q }); 
            }
        } else {
            try writer.print("{s}", .{ 
                \\Missing usage: 
                \\  QUERY [Int]: ask a int exists or not 
                \\  ADD [Int]: insert the int element in 
                \\  RM [Int]: remove the int element out 
                \\
            }); 
        }
    }
}
