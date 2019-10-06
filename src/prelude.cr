require "primitives"
require "atomic"
require "proc"
require "./internal/external_types"
require "./i386_utils"
require "./serial"

lib Crt0
    fun __farcry_early_stack_top: UInt16
end

fun __crystal_once_init : Void*
    Pointer(Void).new 0
end

fun __crystal_raise_overflow : NoReturn
    Serial.puts "OVERFLOW??????"
    while true
    end
end

fun __crystal_once(state : Void*, flag : Bool*, initializer : Void*)
    unless flag.value
        Proc(Nil).new(initializer, Pointer(Void).new 0).call
        flag.value = true
    end
end

# GRUB entrypoint
fun __farcry_entrypoint
    #test = Atomic(UInt32).new 5
    asm("
        # Because it's anoying without this
        .intel_syntax noprefix

        # As Multiboot 2 spec this, we should setup some stack.
        lea esp, __farcry_early_stack_top
        mov ebp, esp

        # We then convert the args passed by Multiboot 2 into somthing that follow the C convention for x86
        push ebx
        push eax

        call __farcry_real_entrypoint

        # if we return here, we halt the CPU.
        hlt
    "
    )
end

module Multiboot2
    @@info_address: UInt64 = 0

    def self.init_from_arguments(multiboot2_magic, multboot2_address)
        @@info_address = multboot2_address.address
    end
end

lib LibCrystalMain
  @[Raises]
  fun __crystal_main(argc : Int32, argv : UInt8**)
end

# Farcry real entrypoint
fun __farcry_real_entrypoint(multiboot2_magic: UInt32, multboot2_address: Void*) : NoReturn
    Serial.initialize(Serial::COM1)
    Multiboot2.init_from_arguments(multiboot2_magic, multboot2_address)

    Serial.puts("Hello World\n")

    LibCrystalMain.__crystal_main(0, Pointer(Pointer(UInt8)).new 0)

    # Never return
    while true
    end
end
