# Manual Memory Management — Stack vs Heap Allocators

<!--toc:start-->
- [Manual Memory Management — Stack vs Heap Allocators](#manual-memory-management-stack-vs-heap-allocators)
  - [Goal: Build two allocators and benchmark them against each other](#goal-build-two-allocators-and-benchmark-them-against-each-other)
    - [Requirements](#requirements)
  - [Thought Process](#thought-process)
    - [odin::memory](#odinmemory)
      - [observations](#observations)
  - [Implementation](#implementation)
    - [Handling the .Alloc branch](#handling-the-alloc-branch)
    - [Handling the .Alloc_Non_Zeroed branch](#handling-the-allocnonzeroed-branch)
    - [Handling the .Free Branch](#handling-the-free-branch)
    - [Handling the .Free_All branch](#handling-the-freeall-branch)
  - [Key Takeaways from this exercise](#key-takeaways-from-this-exercise)
    - [Handling of Memory, Freeing, etc](#handling-of-memory-freeing-etc)
    - [Wrote Odin results](#wrote-odin-results)
<!--toc:end-->

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

- odin::memory
- how to allocate
- how to deallocate
- memory::Allocator
- memcpy

### odin::memory

#### observations

- Looks like this is the "core::mem" package.
- new, free, delete will by default use context.allocator
- As usual need to keep in mind when writing the allocators.
- allocation procedures use the following conventions:
  - if the name contains alloc_bytes or resize_bytes, then the procedure takes in a slice parameters and returns slices
  - if the procedure name contains alloc or resize, then the procedure takes in a raw pointer and returns raw pointers
  - if the procedure name contains free_bytes, then the procedure takes in a slice.
  - if the procedure name contains free, then the procedure takes in a pointer.
- High Level allocation procedures:
  - new: Allocates a single object
  - free: Free a single object
  - make: allocate a group of objects (similar to GO)
  - delete: free a group of objects

## Implementation

1. Okay it says it wants me to create allocators (bump and a free-list allocator)
2. An Allocator is:

```odin
Allocator :: struct {
  procedure: Allocator_Proc,
  data: rawptr,
}
```

So we'll create a BumpAllocator based off that. We'll need to cover the different modes:

- .Alloc
- .Alloc_Non_Zeroed
- .Free
- .Free_All
- .Query_Features
- .Query_Info
- .Resize
- .Resize_Non_Zeroed

### Handling the .Alloc branch

- Need to calculate where the memory starts.
- Will need to factor in alignment.
- After we figure out where it starts we need to check if the incoming data will fit. Should just be a simple take the existing offset, add the size and verify the total is smaller than the backing stores length.
- Move the offset and return a slice of the memory.

### Handling the .Alloc_Non_Zeroed branch

- Should be pretty much the same as the .Alloc branch except we really don't care about the existing memory. The difference between the .Alloc and the .Alloc_Non_Zeroed is just that the first one the consumer is expecting the memory to be zeroed out as opposed to this one which returns the requested space but the user doesn't care what's in there. Scenarios where I'm just going to fill up the data anyway who cares, and I don't want to spend precious cycles setting the values to 0. It's akin to the concept of how .Free_All saves time by just resetting the pointer without actually clearing data and banks on that we're going to fill it up.

### Handling the .Free Branch

- This really isn't a thing in bump allocators. (Free individual segments that is.)

### Handling the .Free_All branch

One of the benefits of the bump allocator is that the free all is just moving the pointer back to beginning. Effectively saying you don't need the info anymore and we're free to write over the old data.

## Key Takeaways from this exercise

### Handling of Memory, Freeing, etc

Have previous experience in C++, so many of the concepts are there but with some extra niceties. Granted I haven't really worked in C++ land in a while so I'm not fully up to date on that but in terms of memory management always practiced a bunch of RAII in terms of remembering to cleanup after myself memory wise. While here in Odin we have some of the niceties that I learned in Golang like the defer to cleanup.

### Wrote Odin results

Very, very similiar to Golang tests. Uses the same conventions to create the test file (_test), as well as the actual structure is the same. So was easy to adapt to the Odin tests.
