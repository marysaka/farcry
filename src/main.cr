require "./arch/gdt"
require "./memory"

Logger.initialize(Logger::Type::All)
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
allocation_result = Memory::PhysicalAllocator.allocate_pages 0x1000

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
