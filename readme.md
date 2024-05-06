# RedBlackTree Unmanaged 

This is a simple implementation of Red Black Tree in zig 0.12 

## Description 

This is an implementation of an unmanaged red-black tree (binary search tree), which maintains a consistent interface with std.Treap, supporting operations for adding, deleting, modifying, and querying using Entry, as well as next access operations akin to an iterator. Additionally, like other binary search trees, this red-black tree also allows for queries of maximum and minimum values, as well as simple one-sided interval constrained extremum queries.

However, unlike the current standard library implementation of std.Treap, its next operation does not use the so-called InorderIterator. Instead, it simply traverses based on the current Node. In a single operation, it has a worst-case time complexity of O(log N), where N is the number of nodes in the tree.

## Issues & Features 

Some incomplete features are listed: 

- Optimization of Node Memory Capacity: 
- - Exploring the use of the effective number of pointer bits for optimizing node memory capacity. 
- - Considering the provision of a more abstract context storage model to reduce the storage burden on pointers, effectively shifting the burden to the tree structure itself. 
- Subtree Size Maintenance: 
- - No plans to maintain the size of subtrees to avoid unnecessary overhead and to align with the design principles of red-black trees.
- - Open to discussions for implementing a size-balanced tree based on subtree sizes for those who may require such functionality, although it's acknowledged that this is not a common requirement.
- Batch Operations Optimization: 
- - Certain constant optimizations for batch operations have not yet been implemented.
- - Contributions from individuals willing to complete these optimizations are highly welcomed.
- Multi-threading Support 

## Example 

The "examples" folder contains a sample code that requires running in interactive mode. It implements the functionality of a collection based on this library. You can enter the directory and compile the code (zig build) to see its effects.

Specifically, for simplicity, this example program in the "examples" folder requires linking to the C standard library.

If possible, you can also find its compiled results in the GitHub releases to test its effectiveness.

