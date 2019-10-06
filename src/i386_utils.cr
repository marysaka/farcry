@[AlwaysInline]
def outb(port : UInt16, val : UInt8)
    asm("outb $1, $0" :: "{dx}"(port), "{al}"(val) :: "volatile")
end

@[AlwaysInline]
def inb(port : UInt16) : UInt8
    result = 0_u8
    asm("inb $1, $0" : "={al}"(result) : "{dx}"(port) :: "volatile")
    result
end
