# VGA Text Mode implementation
class VgaTextMode < LoggerDriver
  WIDTH  = 80
  HEIGHT = 25

  @@vga_text_ptr = Pointer(UInt16).new 0xB8000
  @@pos_x = 0
  @@pos_y = 0
  @@color = Logger::Color::White

  def initialize
    @@vga_text_ptr = Pointer(UInt16).new 0xB8000
  end

  def set_color(color : Logger::Color)
    @@color = color
  end

  def putc(c : UInt8)
    if c == 0xA
      @@pos_x = 0
      @@pos_y += 1
    else
      if @@pos_y == HEIGHT
        @@pos_x = 0
        @@pos_y = 0
      end

      @@vga_text_ptr[@@pos_y * WIDTH + @@pos_x] = c.to_u16 | @@color.to_u16 << 8
      @@pos_x += 1
      if @@pos_x == WIDTH
        @@pos_x = 0
        @@pos_y += 1
      end
    end
  end
end
