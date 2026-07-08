# Manual Memory Management — Stack vs Heap Allocators

## Goal: Build two allocators and benchmark them against each other

### Requirements

Implement a bump allocator: allocate a fixed-size memory region (e.g., 1 MB), maintain a pointer that only moves forward. Support allocate(size) and reset().
Implement a free-list allocator: same fixed region, but track individual free blocks in a linked list. Support allocate(size) and free(ptr).
Write a benchmark: allocate 10,000 blocks of varying sizes (16, 64, 256, 1024 bytes), measure time for each allocator. Print results.
Use odin::memory::OS_Allocator as the underlying backing store.
Bonus: add a deallocate_all() to the bump allocator that frees the entire region at once.

Key concepts: odin::memory, allocate, deallocate, memory::Allocator, pointer arithmetic, memcpy.

## Thought Process

I'm familiar with bump allocators, including using pointer arithmetic to move the pointer forward.

Okay before we get started implementing, lets start looking at the documentation for:

* odin::memory
* how to allocate
* how to deallocate
* memory::Allocator
* memcpy

### odin::memory

#### observations

* Looks like this is the "core::mem" package.
* new, free, delete will by default use context.allocator
* As usual need to keep in mind when writing the allocators.
* allocation procedures use the following conventions:
  * if the name contains alloc_bytes or resize_bytes, then the procedure takes in a slice parameters and returns slices
  * if the procedure name contains alloc or resize, then the procedure takes in a raw pointer and returns raw pointers
  * if the procedure name contains free_bytes, then the procedure takes in a slice.
  * if the procedure name contains free, then the procedure takes in a pointer.
* High Level allocation procedures:
  * new: Allocates a single object
  * free: Free a single object
  * make: allocate a group of objects (similar to GO)
  * delete: free a group of objects

## Implementation

1. Okay it says it wants me to create allocators (bump and a free-list allocator)
2. An Allocator is:

```odin
Allocator :: struct {
  procedure: Allocator_Proc,
  data: rawptr,
}
```
