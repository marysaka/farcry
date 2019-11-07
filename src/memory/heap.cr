require "cryloc"

module Cryloc::HeapManager
  @@init = false
  @@heap_start = Pointer(Void).new(0)
  @@heap_current_pos = Pointer(Void).new(0)
  @@heap_end = Pointer(Void).new(0)

  # 256MB is the max heap possible
  HEAP_MAX_SIZE = 0x10000000

  def self.sbrk(increment : SizeT) : Void*
    return Pointer(Void).new(Cryloc::SimpleAllocator::SBRK_ERROR_CODE)
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
