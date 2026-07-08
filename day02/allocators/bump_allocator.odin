package allocators

import "core:log"
import "core:mem"

BumpAllocator :: struct {
	buffer: []u8,
	offset: int,
}

bump_allocator_proc :: proc(
	allocator_data: rawptr,
	mode: mem.Allocator_Mode,
	size, alignment: int,
	old_memory: rawptr,
	old_size: int,
	location := #caller_location,
) -> (
	[]byte,
	mem.Allocator_Error,
) {
	bump := cast(^BumpAllocator)allocator_data

	switch mode {
	case .Alloc:
		log.infof("[LOG] Allocating %v bytes at %v\n", size, location)
		// 1. calculate where allocation starts
		aligned_offset := bump.offset
		log.infof("[LOG] Current Aligned Offset: %v", aligned_offset)
		if remainder := bump.offset % alignment; remainder != 0 {
			aligned_offset = bump.offset + (alignment - remainder)
			log.infof("[LOG] Offset moved due to alignment: %v", aligned_offset)
		}

		// 2. check there is enough room
		if aligned_offset + size > len(bump.buffer) {
			log.infof("[LOG] Not enough Room to fit new request of size %v", size)
			return nil, .Out_Of_Memory
		}

		// 3. advance bump.offset
		bump.offset = aligned_offset + size
		// 4. return a slice into bump.buffer
		return bump.buffer[aligned_offset:bump.offset], nil
	case .Alloc_Non_Zeroed:
	case .Free:
	// does nothing since Free can't claim individual allocations.
	case .Free_All:
		// 1. reset offset back to zero
		bump.offset = 0
		return nil, nil
	case .Query_Features, .Query_Info:
	case .Resize, .Resize_Non_Zeroed:
	}

	return nil, .Out_Of_Memory
}

make_bump_allocator :: proc(bump: ^BumpAllocator) -> mem.Allocator {
	return mem.Allocator{procedure = bump_allocator_proc, data = bump}
}
