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

### Bump Allocator

Familiar with the concept of a bump allocator.
