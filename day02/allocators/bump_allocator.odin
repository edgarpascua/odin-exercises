package allocators

import "core:log"
import "core:mem"
import "core:slice"

BumpAllocator :: struct {
	buffer: []u8,
	offset: int,
}

BUMP_ALLOCATOR_FEATURES :: mem.Allocator_Mode_Set {
	.Alloc,
	.Alloc_Non_Zeroed,
	.Free_All,
	.Query_Features,
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
		memory_region, err := allocate_region(bump, size, alignment)
		if err != nil {
			return nil, err
		}

		slice.zero(memory_region)
		return memory_region, nil
	case .Alloc_Non_Zeroed:
		memory_region, err := allocate_region(bump, size, alignment)
		if err != nil {
			return nil, err
		}

		return memory_region, nil
	case .Free:
		return nil, nil
	case .Free_All:
		bump.offset = 0
		return nil, nil
	case .Query_Features:
		set := (^mem.Allocator_Mode_Set)(old_memory)
		if set != nil {
			set^ = BUMP_ALLOCATOR_FEATURES
		}
		return nil, nil
	case .Query_Info:
	case .Resize, .Resize_Non_Zeroed:
	}

	return nil, .Out_Of_Memory
}

make_bump_allocator :: proc(bump: ^BumpAllocator) -> mem.Allocator {
	return mem.Allocator{procedure = bump_allocator_proc, data = bump}
}

align_forward :: proc(offset, alignment: int) -> int {
	log.infof("current aligned offset: %v", offset)

	if remainder := offset % alignment; remainder != 0 {
		log.infof("[LOG] Offset moved due to alignment: %v", offset)
		return offset + (alignment - remainder)
	}

	return offset
}

has_enough_backing_space :: proc(offset, size: int, buffer: []u8) -> bool {
	return offset + size > len(buffer)
}

allocate_region :: proc(
	bump: ^BumpAllocator,
	size, alignment: int,
) -> (
	[]byte,
	mem.Allocator_Error,
) {
	aligned_offset := align_forward(bump.offset, alignment)

	if has_enough_backing_space(aligned_offset, size, bump.buffer) {
		log.infof("[LOG] Not enough Room to fit new request of size %v", size)
		return nil, .Out_Of_Memory
	}

	bump.offset = aligned_offset + size
	return bump.buffer[aligned_offset:bump.offset], nil
}
