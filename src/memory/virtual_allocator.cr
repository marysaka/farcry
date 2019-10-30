require "./types"

struct SinglyLinkedList(T)
  @data : T
  @next : Pointer(SinglyLinkedList(T))

  def initialize(@data, @next = Pointer(SinglyLinkedList(T)).new(0))
  end

  property data
  property "next"
end

module Memory
  # Represent a range of memory (that can be physical or virtual depending of the context)
  # TODO: refcount this
  struct MemoryRange
    @start : UInt32
    @size : UInt32

    def initialize(@start, @size)
    end

    property start
    property size
  end

  # Represent an allocation on a virtual address space
  # TODO: refcount this
  struct VirtualAllocation
    @virtual_range : MemoryRange
    @assotiated_physical_ranges : SinglyLinkedList(MemoryRange) | Nil

    def initialize(@virtual_range, @assotiated_physical_ranges = nil)
    end

    property virtual_range
    property assotiated_physical_ranges
  end

  struct VirtualAllocator
    @allocations : Pointer(SinglyLinkedList(VirtualAllocation)) | Nil
    @is_initialized : Bool

    def initialize
      @allocations = nil
      @is_initialized = false
    end

    def finish_initialization
      @is_initialized = true
    end
  end
end
