require "cryloc"

module Cryloc::HeapManager
  @@init = false
  @@heap_start = Pointer(Void).new(0)
  @@heap_current_pos = Pointer(Void).new(0)
  @@heap_current_end = Pointer(Void).new(0)
  @@heap_end = Pointer(Void).new(0)

  # 256MB is the max heap possible
  HEAP_MAX_SIZE = 0x10000000_u32

  def self.sbrk(increment : SizeT) : Void*
    kernel_virtual_allocator = Memory.get_kernel_virtual_allocator

    # first if the heap_start is a null pointer, setup virtual address space
    if @@heap_start.address == 0
      result = kernel_virtual_allocator.value.reserve_space(HEAP_MAX_SIZE)
      case result
      when Memory::Error
        return Pointer(Void).new(Cryloc::SimpleAllocator::SBRK_ERROR_CODE)
      when UInt32
        @@heap_start = Pointer(Void).new(result.to_u64)
        @@heap_current_pos = @@heap_start
        @@heap_end = Pointer(Void).new(result.to_u64 + HEAP_MAX_SIZE)
      end

      result = kernel_virtual_allocator.value.allocate_for_reserved_space(@@heap_start.address.to_u32, Memory::PAGE_SIZE, Memory::Permissions::Read | Memory::Permissions::Write, false)
      case result
      when Memory::Error
        return Pointer(Void).new(Cryloc::SimpleAllocator::SBRK_ERROR_CODE)
      else
        @@heap_current_end = Pointer(Void).new(@@heap_start.address + Memory::PAGE_SIZE)
      end
    end

    if @@heap_current_pos.address + increment > @@heap_end.address
      # OUT OF MEMORY
      return Pointer(Void).new(Cryloc::SimpleAllocator::SBRK_ERROR_CODE)
    end

    current_page_position = farcry_align(@@heap_current_pos.address, Memory::PAGE_SIZE)

    # If we need to return more memory than we currently have, in those cases
    if current_page_position >= @@heap_current_end.address
      page_size_needed = farcry_align(current_page_position - @@heap_current_end.address + Memory::PAGE_SIZE, Memory::PAGE_SIZE)
      result = kernel_virtual_allocator.value.allocate_for_reserved_space(@@heap_current_end.address.to_u32, page_size_needed.to_u32, Memory::Permissions::Read | Memory::Permissions::Write, false)
      case result
      when Memory::Error
        return Pointer(Void).new(Cryloc::SimpleAllocator::SBRK_ERROR_CODE)
      else
        @@heap_current_end = Pointer(Void).new(current_page_position + page_size_needed)
      end
    end

    ptr = @@heap_current_pos

    @@heap_current_pos = Pointer(Void).new(@@heap_current_pos.address + increment)

    ptr
  end
end

# :nodoc:
def cryloc_sbrk(increment : SizeT) : Void*
  Cryloc::HeapManager.sbrk(increment)
end

# :nodoc:
fun __crystal_malloc64(size : UInt64) : Void*
  {% if flag?(:bits32) %}
    if size > UInt32::MAX
      panic("Given size is bigger than UInt32::MAX")
    end
  {% end %}

  Logger.info "HELLO?"
  ptr = malloc(size.to_ssize)

  if ptr.address == 0
    panic("Heap memory exhaustion")
  end

  ptr
end

# :nodoc:
fun __crystal_malloc(size : UInt32) : Void*
  ptr = malloc(size.to_ssize)

  if ptr.address == 0
    panic("Heap memory exhaustion")
  end

  ptr
end

# :nodoc:
fun __crystal_malloc_atomic(size : UInt32) : Void*
  ptr = malloc(size.to_ssize)

  if ptr.address == 0
    panic("Heap memory exhaustion")
  end

  ptr
end

# :nodoc:
fun __crystal_realloc(ptr : Void*, size : UInt32) : Void*
  ptr = realloc(ptr, size.to_ssize)

  if ptr.address == 0
    panic("Heap memory exhaustion")
  end

  ptr
end

# :nodoc:
fun __crystal_malloc64(size : UInt64) : Void*
  {% if flag?(:bits32) %}
    if size > UInt32::MAX
      panic("Given size is bigger than UInt32::MAX")
    end
  {% end %}

  ptr = malloc(size.to_ssize)

  if ptr.address == 0
    panic("Heap memory exhaustion")
  end

  ptr
end

# :nodoc:
fun __crystal_malloc_atomic64(size : UInt64) : Void*
  {% if flag?(:bits32) %}
    if size > UInt32::MAX
      panic("Given size is bigger than UInt32::MAX")
    end
  {% end %}

  ptr = malloc(size.to_ssize)

  if ptr.address == 0
    panic("Heap memory exhaustion")
  end

  ptr
end

# :nodoc:
fun __crystal_realloc64(ptr : Void*, size : UInt64) : Void*
  {% if flag?(:bits32) %}
    if size > UInt32::MAX
      panic("Given size is bigger than UInt32::MAX")
    end
  {% end %}

  ptr = realloc(ptr, size.to_ssize)

  if ptr.address == 0
    panic("Heap memory exhaustion")
  end

  ptr
end
