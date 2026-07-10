package allocators

import "core:mem"

free_list_allocator :: struct {
	buffer: []u8,
	head:   ^free_block,
}

free_block :: struct {
	size: uint,
	next: ^free_block,
}

allocation_header :: struct {
	size: uint,
}

FREE_LIST_ALLOCATOR_FEATURES :: mem.Allocator_Mode_Set{.Query_Features}

free_list_allocator_proc :: proc(
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
	free_list := cast(^free_list_allocator)allocator_data

	switch mode {
	case .Alloc:
		if size <= 0 {
			return nil, .Invalid_Argument
		}
		size_with_header := size + size_of(allocation_header)
		required_size := (size_with_header + (alignment - 1)) & ~(alignment - 1)

		current := free_list.head
		previous: ^free_block = nil

		for current != nil {
			if current.size >= uint(required_size) {
				break
			}

			previous = current
			current = current.next
		}

		if current == nil {
			return nil, .Out_Of_Memory
		}

		remaining := int(current.size) - required_size

		minimum_split_size := size_of(free_block) + alignment
		if remaining > minimum_split_size {
			new_block_address := rawptr(uintptr(rawptr(current)) + uintptr(required_size))
			new_block := cast(^free_block)new_block_address

			new_block.size = uint(remaining)
			new_block.next = current.next

			if previous == nil {
				free_list.head = new_block
			} else {
				previous.next = new_block
			}
		} else {
			if previous == nil {
				free_list.head = current.next
			} else {
				previous.next = current.next
			}
		}

		header := cast(^allocation_header)(current)
		header.size = uint(size)

		user_address := uintptr(rawptr(header)) + uintptr(size_of(allocation_header))

		buffer_start := uintptr(&free_list.buffer[0])

		user_offset := int(user_address - buffer_start)

		return free_list.buffer[user_offset:user_offset + size], nil
	case .Alloc_Non_Zeroed:
	case .Free:
	case .Free_All:
	case .Query_Features:
		set := (^mem.Allocator_Mode_Set)(old_memory)
		if set != nil {
			set^ = FREE_LIST_ALLOCATOR_FEATURES
		}
		return nil, nil
	case .Query_Info:
	case .Resize:
	case .Resize_Non_Zeroed:
	}

	return nil, nil
}

init_free_list_allocator :: proc(buffer: []u8) -> free_list_allocator {
	allocator := free_list_allocator {
		buffer = buffer,
	}

	allocator.head = cast(^free_block)&buffer[0]

	allocator.head.size = uint(len(buffer))
	allocator.head.next = nil

	return allocator
}
