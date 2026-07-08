package allocators

import "core:mem"
import "core:testing"

@(test)
test_bump_allocator_advances_offset :: proc(t: ^testing.T) {
	backing_memory := make([]u8, 1024)
	defer delete(backing_memory)

	bump_data := BumpAllocator {
		buffer = backing_memory,
	}

	bump_allocator := make_bump_allocator(&bump_data)

	_, err := mem.alloc(64, allocator = bump_allocator)

	testing.expect(t, err == nil, "allocation failed")
	testing.expectf(t, bump_data.offset == 64, "expected offset 64, got %v", bump_data.offset)
}

@(test)
test_bump_allocator_seperates_allocations :: proc(t: ^testing.T) {
	backing_memory := make([]u8, 1024)
	defer delete(backing_memory)

	bump_data := BumpAllocator {
		buffer = backing_memory,
	}

	bump_allocator := make_bump_allocator(&bump_data)

	first, _ := mem.alloc(32, allocator = bump_allocator)
	second, _ := mem.alloc(32, allocator = bump_allocator)

	testing.expectf(
		t,
		first != second,
		"expected different memory blocks, got %p and %p",
		first,
		second,
	)
}
