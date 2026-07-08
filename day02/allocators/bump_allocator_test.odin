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

@(test)
test_bump_allocator_out_of_memory :: proc(t: ^testing.T) {
	backing_memory := make([]u8, 32)
	defer delete(backing_memory)

	bump_data := BumpAllocator {
		buffer = backing_memory,
	}

	bump_allocator := make_bump_allocator(&bump_data)

	_, err := mem.alloc(64, allocator = bump_allocator)

	testing.expect(t, err == .Out_Of_Memory, "out of memory error expected")
}

@(test)
test_bump_allocator_allocate_returns_zeroed_memory :: proc(t: ^testing.T) {
	backing_memory := make([]u8, 1024)
	defer delete(backing_memory)

	bump_data := BumpAllocator {
		buffer = backing_memory,
	}

	bump_allocator := make_bump_allocator(&bump_data)

	data, _ := mem.alloc(64, allocator = bump_allocator)

	testing.expect(t, mem.check_zero_ptr(data, 64), "expected zeroed memory")
}

@(test)
test_bump_allocator_allocate_non_zeroed_returns_unzeroed_memory :: proc(t: ^testing.T) {
	backing_memory := make([]u8, 1024)
	defer delete(backing_memory)

	bump_data := BumpAllocator {
		buffer = backing_memory,
	}

	bump_allocator := make_bump_allocator(&bump_data)

	results, err := bump_allocator.procedure(
		bump_allocator.data,
		.Alloc_Non_Zeroed,
		64,
		mem.DEFAULT_ALIGNMENT,
		nil,
		0,
	)

	testing.expect(t, len(results) == 64, "expected returned memory to be length 64")
	testing.expect(t, mem.check_zero(results), "expected zeroed memory")

	results[0] = 1
	results[1] = 2

	testing.expect(t, !mem.check_zero(results), "expected to not be zeroed memory")
	second_call_results := mem.free_all(allocator = bump_allocator)

	testing.expect(t, results[0] == 1, "expected element not zeroed")
	testing.expect(t, results[1] == 2, "expected element not zeroed")
}

@(test)
test_bump_allocator_query_features :: proc(t: ^testing.T) {
	backing_memory := make([]u8, 1024)
	defer delete(backing_memory)

	bump_data := BumpAllocator {
		buffer = backing_memory,
	}

	expected_features := mem.Allocator_Mode_Set {
		.Alloc,
		.Alloc_Non_Zeroed,
		.Free_All,
		.Query_Features,
	}

	bump_allocator := make_bump_allocator(&bump_data)

	features: mem.Allocator_Mode_Set

	_, err := bump_allocator.procedure(bump_allocator.data, .Query_Features, 0, 0, &features, 0)

	testing.expect(t, err == nil, "Query_Features failed")

	testing.expect(
		t,
		features == expected_features,
		"allocator features do not match expected features",
	)

}
