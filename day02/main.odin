package day02

import "allocators"
import "core:fmt"
import "core:mem"

main :: proc() {
	// Requirements called for 1MB of memory.
	backing_memory := make([]u8, 1024 * 1024)
	defer delete(backing_memory)

	// Create the Bump Allocator
	bump_allocator_data := allocators.BumpAllocator {
		buffer = backing_memory,
		offset = 0,
	}

	// Create the allocator
	bump_allocator := allocators.make_bump_allocator(&bump_allocator_data)

	data, err := mem.alloc(128, 8, allocator = bump_allocator)
	if err != nil {
		fmt.println(err)
	}
}
