# VGA Text Mode implementation
module VgaTextMode
  WIDTH  = 80
  HEIGHT = 25

  @@vga_text_ptr = Pointer(UInt16).new 0xB8000
  @@pos_x = 0
  @@pos_y = 0

  def self.initialize
  end

  def self.putc(c : UInt8)
    if c == 0xA
      @@pos_x = 0
      @@pos_y += 1
    else
      @@vga_text_ptr[@@pos_y * WIDTH + @@pos_x] = c.to_u16 | 0xF00
      @@pos_x += 1
      if @@pos_x == WIDTH
        @@pos_x = 0
        @@pos_y += 1
      end

      if @@pos_y == HEIGHT
        @@pos_x = 0
        @@pos_y = 0
      end
    end
  end

  def self.puts(str : String)
    i = 0
    chars = str.to_unsafe
    chars_size = str.bytesize

    raw_puts(chars, chars_size)
  end

  def self.raw_puts(chars : UInt8*, chars_size : Int)
    i = 0

    while i < chars_size
      putc(chars[i])
      i += 1
    end
  end

  def self.put_number(value : Int, base)
    value.internal_to_s(base, false) do |ptr, count|
      raw_puts(ptr, count.to_u64)
    end
  end
end
