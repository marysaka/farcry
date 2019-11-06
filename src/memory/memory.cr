require "./physical_allocator"
require "./virtual_allocator"

module Memory
  @@kernel_virtual_allocator = uninitialized KernelVirtualAllocator

  def self.get_kernel_virtual_allocator : Pointer(KernelVirtualAllocator)
    pointerof(@@kernel_virtual_allocator)
  end

  def self.initialize_kernel_memory_space
    kernel_start = pointerof(LinkerScript.kernel_start).address.to_u32
    kernel_end = pointerof(LinkerScript.kernel_end).address.to_u32

    Memory::PhysicalAllocator.initialize

    @@kernel_virtual_allocator = KernelVirtualAllocator.new

    mapping_result = @@kernel_virtual_allocator.identity_map_pages(kernel_start, kernel_end - kernel_start, Memory::Permissions::Read | Memory::Permissions::Write, false, true)
    if !mapping_result.nil?
      panic("Cannot identity map the kernel")
    end

    @@kernel_virtual_allocator.finish_initialization
  end
end
