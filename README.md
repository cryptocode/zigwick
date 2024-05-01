zig**wick** is a [Fenwick tree](https://en.wikipedia.org/wiki/Fenwick_tree) implementation in [Zig](https://ziglang.org).

## Overview
The main purpose of a Fenwick tree is to efficiently maintain prefix sums. The data structure supports O(log N) range queries and point updates.  

The need to update and query partial sums frequently comes up in competitive programming challenges, but also crop up in real-world applications. 

zigwick never allocates and have no dependencies, not even the standard library (except for tests)

## Building
This library requires a recent Zig build. Last tested with `0.13.0-dev.47+c231d9496`.

To build the library and test it:

```
zig build
zig build test
```


## Types of use

Fenwick trees are generally used in two ways:

1) As an auxiliary data structure for keeping track of partial sums. In this case, the Fenwick tree is kept separate from the actual array of numbers to allow fast indexed access to specific numbers.

2) As the store of both numbers and prefix sums. This reduces memory requirements, but you lose O(1) access to specific numbers by index - this is now a O(log n) operation.

## Create an instance

In the first example we chose to keep numbers and sums separate. This way we can quickly look up numbers by index.

```zig
var data: [5]i32 = .{ -1, -5, -1, 0, 5 };
var tree = [_]i32{0} ** 5;
var partial_sums = Fenwick(i32).initFrom(&tree, &data);

// At this point we can query sums up to an index, or in a range
// Indices are zero-based.
partial_sums.sum(4);
partial_sums.sum(1);
partial_sums.sumRange(2, 4);

// We can add or subtract at given indices, which will efficiently update all prefix sums
partial_sums.update(3, 2);
```

The `tree` array is the backing buffer for the prefix sums. You can chose to allocate this on the heap, of course. The library itself never allocates.

The next example use the tree buffer both for the data and the prefix sums. This saves memory at the cost of O(log n) rather than O(1) access to actual numbers (this isn't needed in many applications, but it's an important consideration if so)

```zig
var tree = [_]i32{0} ** 10;
var fenwick = Fenwick(i32).initZero(&tree);
fenwick.update(4, 10);
fenwick.set(5, 9);
fenwick.get(5);
fenwick.sum(5);
```

See tests for complete examples.
