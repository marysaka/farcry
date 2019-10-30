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

@[AlwaysInline]
def flush_tlb
  asm("
  .intel_syntax noprefix
  mov eax, cr3
  mov cr3, eax" ::: "eax"
                : "volatile")
end

# fun swap_cr3(page_directory_address : Pointer(Void)) : Pointer(Void)
#  old_value = 0
#  asm("
#            mov cr3, $0
#            mov $1, cr3"
#          : "=&r"(old_value)
#          : "r"(page_directory_address.address)
#          : "memory"
#          : "volatile")
#  Pointer(Void).new old_value.to_u64
# end

def enable_paging(page_directory_address : Pointer(Void))
  asm("
  mov $0, %eax
  mov %eax, %cr3

  mov %cr0, %eax
  or $$0x80010001, %eax
  mov %eax, %cr0"
          :: "r"(page_directory_address.address)
          : "eax", "memory"
          : "volatile")
end
