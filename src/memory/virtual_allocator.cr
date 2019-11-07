require "./types"
require "../arch/paging/**"

module Memory
  struct KernelVirtualAllocator
    @page_directory : Arch::Paging::PageDirectory

    def initialize
      @page_directory = Arch::Paging::PageDirectory.new
    end

    def finish_initialization
      @page_directory.enable_paging
    end

    def flush
      @page_directory.flush
    end

    def identity_map_pages(address : UInt32, size : UInt32, permissions : Permissions, user_accesible : Bool, physcial_frames_already_allocated = false) : Nil | Error
      @page_directory.identity_map_pages(address, size, permissions, user_accesible, physcial_frames_already_allocated)
    end

    def allocate(size : UInt32, permissions : Permissions, user_accesible : Bool) : Pointer(Void) | Error
      @page_directory.allocate(size, permissions, user_accesible)
    end

    def reserve_space(size : UInt32) : UInt32 | Error
      @page_directory.reserve_space(size)
    end

    def allocate_for_reserved_space(virtual_address : UInt32, size : UInt32, permissions : Permissions, user_accesible : Bool) : Pointer(Void) | Error
      @page_directory.allocate_for_reserved_space(virtual_address, size, permissions, user_accesible)
    end

    def free(address : UInt32, size : UInt32) : Nil | Error
      @page_directory.free(address, size)
    end
  end
end
