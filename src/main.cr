require "./gdt"

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
