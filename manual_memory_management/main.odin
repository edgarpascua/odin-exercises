package manual_memory_management

import "allocators"
import "core:fmt"
import "core:mem"

main :: proc() {
	// Bump Allocator
	backing_memory := make([]u8, 1024 * 1024)
	defer delete(backing_memory)

	bump_allocator_data := allocators.bump_allocator {
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

	free_list := allocators.init_free_list_allocator(backing_memory_2)

	free_list_allocator := mem.Allocator {
		procedure = allocators.free_list_allocator_proc,
		data      = &free_list,
	}

	memory, err2 := free_list_allocator.procedure(
		free_list_allocator.data,
		.Alloc,
		128,
		mem.DEFAULT_ALIGNMENT,
		nil,
		0,
	)

	if err2 != nil {
		fmt.println(err)
	}
}
