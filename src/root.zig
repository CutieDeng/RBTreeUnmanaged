const std = @import("std");
const testing = std.testing;
const assert = std.debug.assert; 

pub const RBTreeUnmanaged = RedBlackTreeUnmanaged;

pub fn RedBlackTreeUnmanaged(comptime Key: type, comptime compareFn: anytype) type { 
    return struct {
        const Self = @This(); 
        const Order = std.math.Order; 
        const KeyType = Key; 
        pub fn compare(a: Key, b: Key) Order {
            return compareFn(a, b); 
        }
        root: ?*Node = null, 
        pub const Node = struct {
            key: Key, 
            red: bool, 
            parent: ?*Node, 
            children: [2]?*Node, 

            fn checkRecursive_deprecated(self: *Node) void {
                for (self.children) |c| {
                    if (c) |ac| {
                        assert (self == ac.parent); 
                        checkRecursive_deprecated(ac); 
                    }
                }
            }

            pub fn match(self: Node, comptime pattern: ColorMode) bool {
                if (self.red) {
                    return false; 
                }
                switch (pattern) {
                    .@"2" => {
                        inline for (self.children) |c| {
                            if (c) |c2| {
                                if (c2.red) return false; 
                            }
                        }
                    },
                    .@"3l" => {
                        if (self.children[0]) |l| {
                            if (!l.red) {
                                return false; 
                            }
                        } else {
                            return false; 
                        }
                        if (self.children[1]) |r| {
                            if (r.red) return false; 
                        }
                    }, 
                    .@"3r" => {
                        if (self.children[0]) |l| {
                            if (l.red) return false; 
                        }
                        if (self.children[1]) |r| {
                            if (!r.red) return false; 
                        } else {
                            return false; 
                        }
                    }, 
                    .@"4" => {
                        if (self.children[0]) |l| {
                            if (!l.red) return false; 
                        } else {
                            return false; 
                        }
                        if (self.children[1]) |r| {
                            if (!r.red) return false; 
                        } else {
                            return false; 
                        }
                    },
                }
                return true; 
            }
        };
        pub fn getMin(self: Self) ?*Node {
            if (self.root) |r| {
                return self.findSubMin(r); 
            } else {
                return null; 
            }
        }
        pub fn getMinGreaterThan(self: Self, key: Key, allow_eq: bool) ?*Node {
            const root = self.root orelse return null; 
            return self.getMinGreaterThanImpl(root, key, allow_eq);  
        }
        fn getMinGreaterThanImpl(self: Self, node: *Node, key: Key, allow_eq: bool) ?*Node {
            const cp = compare(key, node.key); 
            if (allow_eq and cp == .eq) {
                return node; 
            }
            switch (cp) {
                .eq, .lt => {
                    if (node.children[1]) |c| {
                        return self.getMinGreaterThanImpl(c, key, allow_eq); 
                    } else {
                        return null; 
                    }
                }, 
                .gt => {
                    if (node.children[0]) |c| {
                        const s = self.getMinGreaterThanImpl(c, key, allow_eq); 
                        return s orelse node; 
                    }
                }
            }
        }
        pub fn getMax(self: Self) ?*Node {
            if (self.root) |r| {
                return self.findSubMax(r); 
            } else {
                return null;  
            }
        }
        pub fn getMaxLessThan(self: Self, key: Key, allow_eq: bool) ?*Node {
            const root = self.root orelse return null; 
            return self.getMaxLessThanImpl(root, key, allow_eq);  
        }
        fn getMaxLessThanImpl(self: Self, node: *Node, key: Key, allow_eq: bool) ?*Node {
            const cp = compare(key, node.key); 
            if (allow_eq and cp == .eq) {
                return node; 
            }
            switch (cp) {
                .eq, .gt => {
                    if (node.children[0]) |c| {
                        return self.getMaxLessThanImpl(c, key, allow_eq); 
                    } else {
                        return null; 
                    }
                }, 
                .lt => {
                    if (node.children[1]) |c| {
                        const s = self.getMaxLessThanImpl(c, key, allow_eq); 
                        return s orelse node; 
                    }
                }
            }
        }
        /// Move the value from the location `old` to `new`. 
        /// 
        /// Assume `new` is not inited. 
        fn replace(self: *Self, old: *Node, new: *Node) void {
            new.* = old.*; 
            const link = if (old.parent) |p| &p.children[@intFromBool(p.children[1] == old)] else &self.root;
            assert(link.* == old); 
            link.* = new; 
            for (old.children) |child_node| {
                const child = child_node orelse continue;
                assert(child.parent == old);
                child.parent = new;
            }
        }
        fn removeImplWrap(self: *Self, node: *Node) void {
            const parent = node.parent; 
            if (parent) |p| {
                const idx = @intFromBool(parent.?.children[1] == node); 
                return self.removeImpl(node, p, idx); 
            }
        }
        fn removeImpl(self: *Self, node: ?*Node, parent: *Node, idx: usize) void {
            if (node) |n| {
                assert(n.parent == parent); 
                assert(parent.children[idx] == node); 
                assert(n.red == false); 
            }
            const lparent = parent; 
            // case 2, father is red
            const sibling_optional = lparent.children[1-idx];  
            if (lparent.red) {
                const sibling = sibling_optional.?; 
                assert(!sibling.red);

                // case 2.1, sibling does not have red child 
                const slb = (sibling.children[0] == null or !sibling.children[0].?.red); 
                const srb = (sibling.children[1] == null or !sibling.children[1].?.red); 
                if (slb and srb) {
                    lparent.red = false; 
                    sibling.red = true; 
                    return ; 
                }
                // case 2.2 sibling do have one red child, as opposite 
                if (( slb != srb ) and (slb != (idx != 0))) {
                    if (idx == 0) {
                        self.rotate(lparent, true); 
                    } else {
                        self.rotate(lparent, false);
                    }
                    Self.fillColor(sibling, .@"4");
                    return ; 
                }
                // case 2.3 sibling do have one red child, as same 
                if ((slb != srb) and (slb != (idx == 0))) {
                    if (idx == 0) {
                        self.rotate(sibling, false); 
                    } else {
                        self.rotate(sibling, true);  
                    }
                    const new_sibling = lparent.children[1-idx].?; 
                    if (idx == 0) {
                        Self.fillColor(new_sibling, .@"3r");
                    } else {
                        Self.fillColor(new_sibling, .@"3l"); 
                    }
                    return removeImpl(self, node, parent, idx); 
                }
                // case 2.4 sibling do have two red childs .. 
                assert(!slb and !srb); 
                if (idx == 0) {
                    self.rotate(lparent, true); 
                    Self.fillColor(lparent, .@"3r"); 
                } else {
                    self.rotate(lparent, false); 
                    Self.fillColor(lparent, .@"3l");  
                }
                const new_sibling = sibling.children[1-idx].?; 
                Self.fillColor(new_sibling, .@"2"); 
                sibling.red = true; 
                return ; 
            }
            // case 3, father is black 
            assert(!lparent.red);
            if (sibling_optional == null) {
                // return self.removeImplWrap(self, lparent); 
                assert(false); 
            }
            const sibling = sibling_optional.?; 
            // case 3.1 sibling is red 
            if (sibling.red) {
                // case 3.1.1 the same leftright son of sibling is single black 
                const t_optional = sibling.children[idx];
                const t = t_optional.?; 
                if (t.match(.@"2")) {
                    if (idx == 0) {
                        self.rotate(lparent, true); 
                        Self.fillColor(lparent, .@"3r"); 
                    } else {
                        self.rotate(lparent, false); 
                        Self.fillColor(lparent, .@"3l"); 
                    }
                    Self.fillColor(sibling, .@"2"); 
                    return ; 
                } 
                // case 3.1.2 the same leftright son of sibling contains red son same 
                if (idx == 0) {
                    if (t.match(.@"3l")) {
                        self.rotate(t, false); 
                        Self.fillColor(sibling.children[idx].?, .@"3r"); 
                        return self.removeImpl(node, parent, idx); 
                    }
                } else {
                    if (t.match(.@"3r")) {
                        self.rotate(t, true);  
                        Self.fillColor(sibling.children[idx].?, .@"3l"); 
                        return self.removeImpl(node, parent, idx); 
                    }
                }
                // case 3.1.3 the same leftright son of sibling contains one red son oppositely 
                if (idx == 0) {
                    if (t.match(.@"3r")) {
                        self.rotate(lparent, true) ;
                        self.rotate(lparent, true); 
                        Self.fillColor(t, .@"3l");
                        Self.fillColor(sibling, .@"2");
                        return ; 
                    }
                } else {
                    if (t.match(.@"3l")) {
                        self.rotate(lparent, false); 
                        self.rotate(lparent, false); 
                        Self.fillColor(t, .@"3r"); 
                        Self.fillColor(sibling, .@"2");
                        return ; 
                    }
                }
                // case 3.1.4 the same leftright son of sibling contain two red sons 
                assert(t.match(.@"4"));
                const new_lparent = t.children[1-idx].?; 
                if (idx == 0) {
                    self.rotate(lparent, true); 
                    self.rotate(lparent, true); 
                    Self.fillColor(lparent, .@"3r"); 
                    Self.fillColor(sibling, .@"3l"); 
                    Self.fillColor(new_lparent, .@"2");
                } else {
                    self.rotate(lparent, false); 
                    self.rotate(lparent, false); 
                    Self.fillColor(lparent, .@"3l");
                    Self.fillColor(sibling, .@"3r");
                    Self.fillColor(new_lparent, .@"2"); 
                }
                return ; 
            } 
            // check sibling is 2 pattern or not 
            // simple case 
            if (sibling.match(.@"2")) {
                sibling.red = true; 
                return self.removeImplWrap(lparent); 
            }
            // adjust case 
            if (idx == 0) {
                if (sibling.match(.@"3l")) {
                    self.rotate(sibling, false); 
                    Self.fillColor(sibling.parent.?, .@"3r");
                    return self.removeImpl(node, parent, idx); 
                }
            } else {
                if (sibling.match(.@"3r")) {
                    self.rotate(sibling, true) ;
                    Self.fillColor(sibling.parent.?, .@"3l");
                    return self.removeImpl(node, parent, idx); 
                }
            }
            // handle case 
            if (idx == 0) {
                if (sibling.match(.@"3r")) {
                    self.rotate(lparent, true); 
                    Self.fillColor(lparent, .@"2"); 
                    Self.fillColor(sibling, .@"2"); 
                    Self.fillColor(sibling.children[1-idx].?, .@"2"); 
                    return ; 
                }
            } else {
                if (sibling.match(.@"3l")) {
                    self.rotate(lparent, false); 
                    Self.fillColor(lparent, .@"2"); 
                    Self.fillColor(sibling, .@"2"); 
                    Self.fillColor(sibling.children[1-idx].?, .@"2"); 
                    return ; 
                }
            }
            // difficult case 
            if (sibling.match(.@"4")) {
                if (idx == 0) {
                    self.rotate(lparent, true); 
                    Self.fillColor(lparent, .@"3r"); 
                    Self.fillColor(sibling, .@"2"); 
                    Self.fillColor(sibling.children[1-idx].?, .@"2"); 
                } else {
                    self.rotate(lparent, false); 
                    Self.fillColor(lparent, .@"3l"); 
                    Self.fillColor(sibling, .@"2"); 
                    Self.fillColor(sibling.children[1-idx].?, .@"2"); 
                }
                return ; 
            } 
            assert(false); 
        }
        fn remove(self: *Self, node: *Node) void {
            // check it has sub nodes or not ~ 
            var sub_node : ?*Node = null; 
            if (node.children[0]) |c| {
                sub_node = self.findSubMax(c); 
            } else if (node.children[1]) |c| {
                sub_node = self.findSubMin(c); 
            }
            if (sub_node) |s| {
                var buffer: Node = undefined; 
                self.replace(s, &buffer); 
                self.replace(node, s); 
                self.replace(&buffer, node); 
                s.key = node.key; 
            }

            // check it has left sub node 
            if (node.children[0]) |c| {
                const idx = @intFromBool(node.parent.?.children[1] == node); 
                const link = &node.parent.?.children[idx]; 
                link.* = c;  
                c.parent = node.parent; 
                if (c.red) {
                    c.red = false; 
                    return ; 
                } else {
                    return self.removeImpl(c, c.parent.?, idx); 
                }
            }
            if (node.children[1]) |c| {
                const idx = @intFromBool(node.parent.?.children[1] == node); 
                const link = &node.parent.?.children[idx]; 
                link.* = c; 
                c.parent = node.parent; 
                if (c.red) {
                    c.red = false; 
                    return ; 
                } else {
                    return self.removeImpl(c, c.parent.?, idx); 
                } 
            }

            // then node is to be removed ~ 
            assert(node.children[0] == null and node.children[1] == null); 
            // case 1: if node is red ~ remove simply ~
            if (node.red) {
                const link = if (node.parent) |p| &p.children[@intFromBool(p.children[1] == node)] else &self.root; 
                assert(link.* == node); 
                link.* = null; 
                return ; 
            }
            // case 2: if node is black, and its root 
            if (node.parent == null) {
                assert(node == self.root); 
                self.root = null; 
                return ; 
            } 
            // case 3: otherwise, remove the normal black node 
            const parent = node.parent.?; 
            const idx = @intFromBool(parent.children[1] == node); 
            parent.children[idx] = null; 
            return self.removeImpl(null, parent, idx); 
        }
        fn findSubMin(self: Self, node: *Node) *Node {
            return self.findSubDirection(node, 0); 
        }
        fn findSubMax(self: Self, node: *Node) *Node {
            return self.findSubDirection(node, 1); 
        }
        fn findSubDirection(self: Self, node: *Node, comptime idx: usize) *Node {
            if (node.children[idx]) |child| {
                return self.findSubDirection(child, idx); 
            } else {
                return node; 
            } 
        }
        fn insertNode(self: *Self, node: *Node) void {
            const parent = node.parent;
            const key = node.key;  
            if (parent) |p| {
                const idx = @intFromBool(compare(key, p.key) == .gt);
                const link = &p.children[idx]; 
                assert(link.* == null or link.* == node);  
                link.* = node; 
                // case 1: parent is black, so we're done 
                if ( !p.red ) {
                    node.red = true; 
                    return ; 
                }
                // case 2: parent is red, uncle is black, so just rotate 
                const grandparent = p.parent orelse unreachable; 
                const idx2 = @intFromBool(p == grandparent.children[1]); 
                const uncle = grandparent.children[1-idx2]; 
                var uncle_red : bool = false; 
                if (uncle) |u| {
                    uncle_red = u.red; 
                }  
                if (!uncle_red) {
                    if (idx == 0) {
                        if (idx2 == 0) {
                            self.rotate(grandparent, false); 
                            fillColor(p, .@"4"); 
                        } else {
                            self.rotate(p, false); 
                            self.rotate(grandparent, true); 
                            fillColor(node, .@"4"); 
                        }
                    } else {
                        if (idx2 == 0) {
                            self.rotate(p, true); 
                            self.rotate(grandparent, false); 
                            fillColor(node, .@"4"); 
                        } else {
                            self.rotate(grandparent, true); 
                            fillColor(p, .@"4"); 
                        }
                    }
                    return ; 
                }
                // case 3: 
                node.red = true; 
                p.red = false; 
                ( uncle orelse unreachable ).red = false; 
                grandparent.red = false; 
                self.insertNode(grandparent); 
            } else {
                self.root = node; 
            }
        }
        fn insert(self: *Self, key: Key, parent: ?*Node, node: *Node) void {
            node.* = .{ .key = key, .red = false, .parent = parent, .children = .{ null, null } }; 
            return self.insertNode(node); 
        }
        fn rotate(self: *Self, node: *Node, comptime left: bool) void { 
            const parent = node.parent; 
            const link = if (parent) |p| &p.children[@intFromBool(p.children[1] == node)] else &self.root; 
            const son_link = &node.children[@intFromBool(left)]; 
            const son = son_link.*.?; 
            const grandson_link = &son.children[@intFromBool(!left)]; 
            const grandson = grandson_link.*; 

            link.* = son; 
            son.parent = parent; 

            grandson_link.* = node; 
            node.parent = son; 

            son_link.* = grandson; 
            if (grandson) |g| {
                g.parent = node; 
            } 
        }
        const ColorMode = enum {
            @"2", 
            @"3l",
            @"3r",
            @"4",
        };
        fn forceColor(node: *Node, comptime cm: ColorMode) void {
            switch (cm) {
                .@"2" => {
                    node.red = false;  
                }, 
                .@"3l" => {
                    node.red = false; 
                    (node.children[0] orelse unreachable).*.red = true; 
                }, 
                .@"3r" => {
                    node.red = false; 
                    (node.children[1] orelse unreachable).*.red = true; 
                }, 
                .@"4" => {
                    node.red = false;
                    (node.children[0] orelse unreachable).*.red = true; 
                    (node.children[1] orelse unreachable).*.red = true; 
                }, 
            } 
        }
        fn fillColor(node: *Node, comptime color_mode: ColorMode) void {
            return forceColor(node, color_mode); 
        }
        fn find(self: Self, key: Key, parent_ref: *?*Node) ?*Node {
            var node = self.root; 
            var parent : ?*Node = null; 
            defer parent_ref.* = parent; 
            while (node) |current| {
                const order = compare(key, current.key); 
                if (order == .eq) break; 
                parent = current; 
                node = current.children[@intFromBool(order == .gt)]; 
            }
            return node;  
        }
        pub fn nextNode(self: Self, node: *Node) ?*Node {
            if (node.children[1]) |rson| {
                return self.findSubMin(rson); 
            } 
            var up: *Node = node; 
            while (true) {
                if (up.parent) |p| {
                    const he_is_left = p.children[0] == up; 
                    if (he_is_left) {
                        return p; 
                    } else {
                        up = p; 
                    }
                } else {
                    return null; 
                }
            }
        } 
        pub const Entry = struct {
            key: Key, 
            tree: *Self, 
            node: ?*Node, 
            context: union(enum) {
                inserted_under: ?*Node, 
                removed, 
            }, 
            pub fn set(self: *Entry, new_node: ?*Node) void {
                defer self.node = new_node; 
                if (self.node) |old| {
                    if (new_node) |new| {
                        self.tree.replace(old, new); 
                    } else {
                        self.tree.remove(old); 
                        self.context = .removed;
                    }
                } else if (new_node) |new| {
                    var parent: ?*Node = undefined; 
                    switch (self.context) {
                        .inserted_under => |p| parent = p, 
                        .removed => assert(self.tree.find(self.key, &parent) == null),
                    }
                    self.tree.insert(self.key, parent, new); 
                    self.context = .{ .inserted_under = parent };
                }
            }
        };
        pub fn getEntryFor(self: *Self, key: Key) Entry {
            var parent: ?*Node = undefined;
            const node = self.find(key, &parent);
            return Entry{
                .key = key,
                .tree = self,
                .node = node,
                .context = .{ .inserted_under = parent },
            };
        }
        pub fn getEntryForExisting(self: *Self, node: *Node) Entry {
            return Entry {
                .key = node.key, 
                .tree = self, 
                .node = node, 
                .context = .{ .inserted_under = node.parent }, 
            }; 
        }
    };
}

const DbgI64RBTUnmanaged = RedBlackTreeUnmanaged(i64, std.math.order); 

pub fn ArrayRedBlackTree(RbtUnmanaged: type) type { 
    return struct {
        pub const TreeType = RbtUnmanaged; 
        pub const Allocator = std.mem.Allocator; 
        pub const KeyType = RbtUnmanaged.KeyType; 
        const Node = TreeType.Node; 
        const Self = @This(); 
        inner_tree: TreeType, 
        allocator: Allocator, 
        items: []Node, 
        capacity: usize, 
        pub fn init(allocator: Allocator) Self {
            var arbt: Self = undefined; 
            arbt.allocator = allocator; 
            arbt.inner_tree = .{}; 
            arbt.items = &.{}; 
            arbt.capacity = 0; 
            return arbt; 
        }
        pub fn deinit(self: Self) void {
            self.allocator.free(self.allocatedSlice()); 
        }
        pub fn ensureTotalCapacityPrecise(self: *Self, new_capacity: usize) Allocator.Error!void {
            if (self.capacity >= new_capacity) { return ; } 
            const old_memory = self.allocatedSlice(); 
            if (self.allocator.resize(old_memory, new_capacity)) {
                self.capacity = new_capacity; 
            } else {

                const new_memory = try self.allocator.alloc(Node, new_capacity); 
                self.adjust(self.items, new_memory[0..self.items.len]); 

                self.allocator.free(old_memory); 
                self.items.ptr = new_memory.ptr; 
                self.capacity = new_capacity; 
            }
        }
        pub fn append(self: *Self, key: KeyType) !bool {
            var e = self.inner_tree.getEntryFor(key); 
            const cache_root = self.inner_tree.root; 
            if (e.node) |_| {
                return false; 
            } else {
                const o = try self.addOne(); 
                if (cache_root != self.inner_tree.root) {
                    e = self.inner_tree.getEntryFor(key); 
                }
                e.set(o); 
                return true; 
            }
        }
        pub fn remove(self: *Self, key: KeyType) bool {
            var e = self.inner_tree.getEntryFor(key);
            if (e.node) |l| {
                e.set(null); 
                const last = &self.items[self.items.len - 1]; 
                if (last != l) { 
                    var to_swap = self.inner_tree.getEntryForExisting(last); 
                    to_swap.set(l); 
                }
                self.items.len -= 1; 
                return true; 
            } else {
                return false; 
            }
        }
        pub fn exists(self: *Self, key: KeyType) bool {
            const e = self.inner_tree.getEntryFor(key); 
            return e.node != null; 
        }
        fn addOne(self: *Self) Allocator.Error!*Node {
            const new_len = self.items.len + 1; 
            try self.ensureTotalCapacity(new_len); 
            self.items.len += 1; 
            return &self.items[self.items.len - 1]; 
        }
        pub fn ensureUnusedCapacity(self: *Self, additional_count: usize) Allocator.Error!void {
            return self.ensureTotalCapacity(self.items.len + additional_count); 
        }
        pub fn clearAndFree(self: *Self) void {
            self.allocator.free(self.allocatedSlice()); 
            self.items.len = 0; 
            self.capacity = 0; 
        }
        pub fn ensureTotalCapacity(self: *Self, new_capacity: usize) Allocator.Error!void {
            if (self.capacity >= new_capacity) return ; 
            const better_capacity = growCapacity(self.capacity, new_capacity); 
            return self.ensureTotalCapacityPrecise(better_capacity); 
        }
        fn adjust(self: *Self, src: []Node, target: []Node) void {
            for (src, target) |*s, *n| {
                var e = self.inner_tree.getEntryForExisting(s); 
                e.set(n); 
            }
        }
        fn allocatedSlice(self: Self) []Node {
            // `items.len` is the length, not the capacity.
            return self.items.ptr[0..self.capacity];
        }
    }; 
} 

fn growCapacity(current: usize, minimum: usize) usize {
    var new = current;
    if (false) {
        return minimum; 
    }
    while (true) {
        new +|= new / 2 + 8;
        if (new >= minimum)
            return new;
    }
}

const I32SetU = RedBlackTreeUnmanaged(i32, std.math.order); 
const I32Set = ArrayRedBlackTree(I32SetU); 

test {
    var a = I32Set.init(testing.allocator); 
    defer a.deinit(); 
    const m = a.inner_tree.getMax();  
    std.debug.assert(m == null);
}

test {
    var set = I32Set.init(testing.allocator); 
    defer set.deinit(); 
    for (0..3) |_| {
        _ = try set.append(1); 
    }
    const len = set.items.len; 
    assert(len == 1);     
}

fn dbg_deprecated(node: ?*I32Set.Node) void {
    std.log.warn("[DBG]|root: {x}", .{ @intFromPtr(node) }); 
    if (node) |n| {
        for (n.children) |child| {
            std.log.warn("[DBG]|  son: {x}", .{ @intFromPtr(child)}); 
        }
    }
}

test {
    var set = I32Set.init(testing.allocator); 
    defer set.deinit(); 
    for (3..5) |i| {
        _ = try set.append(@as(i32, @intCast(i))); 
    }
    for (1..3) |i| {
        _ = try set.append(@as(i32, @intCast(i))); 
    }
    for (7..10) |i| {
        _ = try set.append(@as(i32, @intCast(i))); 
    }
    for (5..7) |i| {
        _ = try set.append(@as(i32, @intCast(i))); 
    }
    assert ( set.items.len == 9 ); 
    const m = set.inner_tree.getMin(); 
    assert (m != null); 
    var mit = m; 
    var c : i32 = 0; 
    while (mit != null) : (mit = set.inner_tree.nextNode(mit.?)) {
        const k = mit.?.key; 
        assert (k == c + 1); 
        c = k; 
    }
    assert ( c == 9 ); 
    for (1..10) |v| {
        if (v != 7) {
            assert ( set.remove(@as(i32, @intCast(v))) ); 
        }
    }
    assert ( set.items.len == 1 ); 
    assert ( set.inner_tree.root.?.key == 7 ); 
} 