require "./types"
require "../arch/paging/**"

module Memory
  # The kernel virtual memory allocator.
  struct KernelVirtualAllocator
    @page_directory : Arch::Paging::PageDirectory

    # :nodoc:
    # This is exposed for some the kernel virtual allocator setup.
    def initialize
      @page_directory = Arch::Paging::PageDirectory.new
    end

    # Finalize the kernel virtual allocator initialization by enabling Paging.
    def finish_initialization
      @page_directory.enable_paging
    end

    # Flush the TLB of the MMU
    def flush
      @page_directory.flush
    end

    # Identity map the given physical range to the same virtual range.
    #
    # ## Preconditions:
    # - `address` must be aligned to `Memory::PAGE_SIZE`.
    # - `size` must be aligned to `Memory::PAGE_SIZE`.
    # - The virtual range **must** be **freed**.
    #
    # ## Postconditions:
    # - The virtual range is **allocated**.
    def identity_map_pages(address : UInt32, size : UInt32, permissions : Permissions, user_accesible : Bool, physcial_frames_already_allocated = false) : Nil | Error
      @page_directory.identity_map_pages(address, size, permissions, user_accesible, physcial_frames_already_allocated)
    end

    # Allocate a given amount of virtual memory contiguously.
    #
    # ## Preconditions:
    # - `size` must be aligned to `Memory::PAGE_SIZE`.
    #
    # ## Postconditions:
    # - The return contains an address to the virtual memory range that is **allocated**.
    def allocate(size : UInt32, permissions : Permissions, user_accesible : Bool) : Pointer(Void) | Error
      @page_directory.allocate(size, permissions, user_accesible)
    end

    # Reserve a given amount of virtual memory contiguously.
    #
    # ## Preconditions:
    # - `size` must be aligned to `Memory::PAGE_SIZE`.
    #
    # ## Postconditions:
    # - The return contains an address to the virtual memory range that is **reserved**.
    def reserve_space(size : UInt32) : UInt32 | Error
      @page_directory.reserve_space(size)
    end

    # Allocate a given amount of virtual memory contiguously a reserved virtual memory range.
    #
    # ## Preconditions:
    # - `virtual_address` must be aligned to `Memory::PAGE_SIZE`.
    # - `size` must be aligned to `Memory::PAGE_SIZE`.
    #
    # ## Postconditions:
    # - The return contains a pointer to `virtual_address` that is now **allocated**.
    def allocate_for_reserved_space(virtual_address : UInt32, size : UInt32, permissions : Permissions, user_accesible : Bool) : Pointer(Void) | Error
      @page_directory.allocate_for_reserved_space(virtual_address, size, permissions, user_accesible)
    end

    # Free a virtual range at the given virtual address with a given size.
    #
    # ## Preconditions:
    # - `address` must be aligned to `Memory::PAGE_SIZE`.
    # - `size` must be aligned to `Memory::PAGE_SIZE`.
    # - The virtual range **must** be **allocated**.
    #
    # ## Postconditions:
    # - The virtual range is **freed**.
    def free(address : UInt32, size : UInt32) : Nil | Error
      @page_directory.free(address, size)
    end
  end
end
