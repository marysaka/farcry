require "./arch/gdt"
require "./arch/paging/**"
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

Memory.initialize_kernel_memory_space

Logger.info "MMU ON"

kernel_virtual_allocator = Memory.get_kernel_virtual_allocator

class Testing
  property some_integer : UInt32 = 0
  property some_array : UInt8[0x100] = StaticArray(UInt8, 0x100).new

  def finalize
    Logger.puts "BYYYYE"
  end
end

some_testing = Testing.new
some_testing.some_integer = 0x42
some_testing.some_array[0] = 0x48
some_testing.some_array[1] = 0x69
some_testing.some_array[2] = 0x69
some_testing.some_array[3] = 0x69
some_testing.some_array[4] = 0x69
some_testing.some_array[5] = 0x00

Logger.info "some_testing.some_integer: 0x", false
Logger.put_number some_testing.some_integer, 16
Logger.puts "\n"

Logger.info "some_testing.some_array: ", false
Logger.raw_puts some_testing.some_array.to_unsafe, 5
Logger.puts "\n"

some_testing = Testing.new
some_testing.some_integer = 0x42
some_testing.some_array[0] = 0x48
some_testing.some_array[1] = 0x69
some_testing.some_array[2] = 0x69
some_testing.some_array[3] = 0x69
some_testing.some_array[4] = 0x69
some_testing.some_array[5] = 0x00

Logger.info "some_testing.some_integer: 0x", false
Logger.put_number some_testing.some_integer, 16
Logger.puts "\n"

Logger.info "some_testing.some_array: ", false
Logger.raw_puts some_testing.some_array.to_unsafe, 5
Logger.puts "\n"
