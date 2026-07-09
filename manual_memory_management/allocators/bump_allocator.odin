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
		return nil, .Mode_Not_Implemented
	case .Resize:
		old_offset := offset_from_pointer(bump, old_memory)
		end_of_allocation := old_offset + old_size

		if end_of_allocation != bump.offset {
			return nil, .Invalid_Argument
		}

		requested_bump_offset := old_offset + size

		if (requested_bump_offset > len(bump.buffer)) {
			return nil, .Out_Of_Memory
		}

		bump.offset = old_offset + size

		memory_region := bump.buffer[old_offset:old_offset + size]
		slice.zero(memory_region)
		return memory_region, nil

	case .Resize_Non_Zeroed:
		old_offset := offset_from_pointer(bump, old_memory)
		end_of_allocation := old_offset + old_size

		if end_of_allocation != bump.offset {
			return nil, .Invalid_Argument
		}

		requested_bump_offset := old_offset + size

		if (requested_bump_offset > len(bump.buffer)) {
			return nil, .Out_Of_Memory
		}

		bump.offset = old_offset + size

		return bump.buffer[old_offset:old_offset + size], nil
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

offset_from_pointer :: proc(bump: ^BumpAllocator, ptr: rawptr) -> int {
	buffer_start := uintptr(raw_data(bump.buffer))
	address := uintptr(ptr)

	return int(address - buffer_start)
}
