# Simple UART implementation
module Serial
  COM1 = 0x3F8_u16

  @@port : UInt16 = 0

  def self.initialize(port : UInt16)
    @@port = port

    # Disable all interrupts
    outb(port + 1, 0x00)
    # Enable DLAB (set baud rate divisor)
    outb(port + 3, 0x80)
    # Set divisor to 3 (lo byte)
    outb(port, 0x03)
    # Set divisor to 3 (hi byte)
    outb(port + 1, 0x00)
    # 8 bits, no parity, one stop bit
    outb(port + 3, 0x03)
    # Enable FIFO, clear them, with 14-byte threshold
    outb(port + 2, 0xC7)
    # IRQs enabled, RTS/DSR set
    outb(port + 4, 0x0B)
  end

  def self.transport_empty? : Bool
    (inb(@@port + 5) & 0x20) != 0
  end

  def self.received_data? : Bool
    inb(@@port + 5) & 1
  end

  def self.getc : UInt8
    unless received_data?
    end

    inb(@@port)
  end

  def self.putc(c : UInt8)
    unless transport_empty?
    end

    outb(@@port, c)
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

  def self.put_number(value : Int, base, padding = 0)
    value.internal_to_s(base, false) do |ptr, count|
      tmp_count = count
      while padding > tmp_count
        puts "0"
        tmp_count += 1
      end

      raw_puts(ptr, count.to_u64)
    end
  end

  private def self.get_ansi_color(color : Logger::Color) : Int32
    case color
    when Logger::Color::Black
      30
    when Logger::Color::Blue
      34
    when Logger::Color::Green
      32
    when Logger::Color::Cyan
      36
    when Logger::Color::Red
      31
    when Logger::Color::Magenta
      95
    when Logger::Color::Gray
      37
    when Logger::Color::DarkGray
      90
    when Logger::Color::BrightBlue
      94
    when Logger::Color::BrightGreen
      92
    when Logger::Color::BrightCyan
      96
    when Logger::Color::BrightRed
      91
    when Logger::Color::BrightMagenta
      95
    when Logger::Color::Yellow
      33
    else
      # default is white
      97
    end
  end

  def self.set_color(color : Logger::Color)
    puts "\x1b["
    put_number get_ansi_color(color), 10
    puts "m"
  end
end
