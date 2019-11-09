# compiler-rt needs some bare minimal to be linkable (memcmp, memcpy, abort, and assert)
fun memcmp(s1 : UInt8*, s2 : UInt8*, n : UInt32) : Int32
  until n == 0
    if s1.value != s2.value
      return (s1.value.to_i32 - s2.value.to_i32)
    end
    n -= 1
  end
  0_i32
end

fun memcpy(dest : UInt8*, src : UInt8*, n : UInt32)
  n.times do |i|
    dest[i] = src[i]
  end
end

fun memset(s : UInt8*, c : Int32, n : UInt32) : UInt8*
  n.times do |i|
    s[i] = c.to_u8
  end
  s
end

def __strlen(str) : UInt32
  res = 0_u32
  until str[res] == 0
    res += 1
  end
  res
end

fun abort : NoReturn
  Logger.error "Aborted"
  while true
    asm("hlt")
  end
end

def panic(panic_message : String) : NoReturn
  Logger.error panic_message
  abort
end

# see include/assert.h
fun __assert(msg : UInt8*, file : UInt8*, line : UInt32)
  Logger.serial_logger.raw_puts(msg, __strlen(msg))
  Logger.serial_logger.raw_puts(file, __strlen(file))
  Logger.serial_logger.puts "Line: "
  Logger.serial_logger.put_number(line, 10)
  abort
end

struct SinglyLinkedList(T)
  @data : T
  @next : Pointer(SinglyLinkedList(T))

  def initialize(@data, @next = Pointer(SinglyLinkedList(T)).new(0))
  end

  property data
  property "next"
end

macro farcry_max(a, b)
  {{a}} >= {{b}} ? {{a}} : {{b}}
end

macro farcry_align(size, align)
  (({{size}} + {{align}} - 1) & ~({{align}} - 1))
end