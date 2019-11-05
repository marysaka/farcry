require "./arch/gdt"
require "./arch/paging/**"
require "./memory"

Logger.initialize(Logger::Type::Serial)
Logger.info "Welcome to FarCry"

Logger.debug "Setup GDT"
gdt = Pointer(GDT).new 0x800
gdt.value.setup_gdt
gdt.value.flush
Logger.debug "GDT Setup done"

lib LibCrt0
  $__farcry_early_stack_bottom : UInt8
  $__farcry_early_stack_top : UInt8
end

stack_bottom = pointerof(LibCrt0.__farcry_early_stack_bottom)
stack_top = pointerof(LibCrt0.__farcry_early_stack_top)
stack_size = stack_top - stack_bottom

Logger.debug "Stack bottom: 0x", false
Logger.put_number stack_bottom.address, 16
Logger.puts "\n"

Logger.debug "Stack size: 0x", false
Logger.put_number stack_size, 16
Logger.puts "\n"

Logger.info "Now showing the stackdump"
Logger.print_hex stack_bottom, stack_size

Memory::PhysicalAllocator.initialize
allocation_result = Memory::PhysicalAllocator.allocate Memory::PAGE_SIZE

case allocation_result
when Pointer(Void)
  Logger.info "Allocated a physical page at 0x", false
  Logger.put_number allocation_result.address, 16
  Logger.puts "\n"
else
  Logger.error "Cannot allocate: ", false
  Logger.put_number allocation_result.to_u32, 16
  Logger.puts "\n"
  Memory::PhysicalAllocator.dump
end

Logger.info "Job done"

kernel_start = pointerof(LinkerScript.kernel_start).address.to_u32
kernel_end = pointerof(LinkerScript.kernel_end).address.to_u32
kernel_page_directory = Arch::Paging::PageDirectory.new
mapping_result = kernel_page_directory.identity_map_pages(kernel_start, kernel_end - kernel_start, Memory::Permissions::Read | Memory::Permissions::Write, false, true)
if !mapping_result.nil?
  panic("Cannot identity map the kernel")
end

kernel_page_directory.enable_paging
Logger.info "MMU ON"

allocation_result = kernel_page_directory.allocate 0x10000000, Memory::Permissions::Read | Memory::Permissions::Write, false
case allocation_result
when Pointer(Void)
  Logger.info "Allocated a virtual pages at 0x", false
  Logger.put_number allocation_result.address, 16
  Logger.puts "\n"

  ptr_test = allocation_result.as(UInt8*)
  ptr_test.value = 42
else
  Logger.error "Cannot allocate: ", false
  Logger.put_number allocation_result.to_u32, 16
  Logger.puts "\n"
  panic("Cannot allocate virtual page in the kernel")
end

allocation_result = kernel_page_directory.free allocation_result.address.to_u32, 0x10000000

if allocation_result.nil?
  Logger.info "Freed virtual pages!"
end

allocation_result = kernel_page_directory.allocate 0x10000000, Memory::Permissions::Read | Memory::Permissions::Write, false
case allocation_result
when Pointer(Void)
  Logger.info "Allocated a virtual pages at 0x", false
  Logger.put_number allocation_result.address, 16
  Logger.puts "\n"

  ptr_test = allocation_result.as(UInt8*)
  ptr_test.value = 42
else
  Logger.error "Cannot allocate: ", false
  Logger.put_number allocation_result.to_u32, 16
  Logger.puts "\n"
  panic("Cannot allocate virtual page in the kernel")
end

allocation_result = kernel_page_directory.free allocation_result.address.to_u32, 0x10000000

if allocation_result.nil?
  Logger.info "Freed virtual pages!"
end
