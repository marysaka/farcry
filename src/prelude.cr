require "primitives"
require "atomic"

# GRUB entrypoint
fun __farcry_entrypoint
    #test = Atomic(UInt32).new 5
    asm("hlt");
end

