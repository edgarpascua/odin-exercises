package manual_memory_management

import "allocators"
import "core:fmt"
import "core:mem"

main :: proc() {
	// Bump Allocator
	backing_memory := make([]u8, 1024 * 1024)
	defer delete(backing_memory)

	bump_allocator_data := allocators.BumpAllocator {
		buffer = backing_memory,
		offset = 0,
	}

	bump_allocator := allocators.make_bump_allocator(&bump_allocator_data)

	data, err := mem.alloc(128, 8, allocator = bump_allocator)
	if err != nil {
		fmt.println(err)
	}

	// Free List Allocator
	backing_memory_2 := make([]u8, 1024 * 1024)
	defer delete(backing_memory_2)


	free_list_allocator_data := allocators.FreeListAllocator {
		buffer = backing_memory_2,
		head   = FreeBlock,
	}
}
