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

Memory.initialize_kernel_memory_space

Logger.info "MMU ON"

kernel_virtual_allocator = Memory.get_kernel_virtual_allocator

allocation_result = kernel_virtual_allocator.value.allocate 0x10000000, Memory::Permissions::Read | Memory::Permissions::Write, false
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

allocation_result = kernel_virtual_allocator.value.free allocation_result.address.to_u32, 0x10000000

if allocation_result.nil?
  Logger.info "Freed virtual pages!"
end

allocation_result = kernel_virtual_allocator.value.allocate 0x10000000, Memory::Permissions::Read | Memory::Permissions::Write, false
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

allocation_result = kernel_virtual_allocator.value.free allocation_result.address.to_u32, 0x10000000

if allocation_result.nil?
  Logger.info "Freed virtual pages!"
end
