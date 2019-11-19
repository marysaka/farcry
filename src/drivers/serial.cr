# Simple UART implementation
struct Serial < LoggerDriver
  # The COM1 port
  COM1 = 0x3F8_u16

  @port : UInt16

  # Create a new Serial instance on the given `port`.
  def initialize(@port = COM1)
    # Disable all interrupts
    outb(@port + 1, 0x00)
    # Enable DLAB (set baud rate divisor)
    outb(@port + 3, 0x80)
    # Set divisor to 3 (lo byte)
    outb(@port, 0x03)
    # Set divisor to 3 (hi byte)
    outb(@port + 1, 0x00)
    # 8 bits, no parity, one stop bit
    outb(@port + 3, 0x03)
    # Enable FIFO, clear them, with 14-byte threshold
    outb(@port + 2, 0xC7)
    # IRQs enabled, RTS/DSR set
    outb(@port + 4, 0x0B)
  end

  # Check if all the data was sent.
  def transport_empty? : Bool
    (inb(@port + 5) & 0x20) != 0
  end

  # Check if any data was received.
  def received_data? : Bool
    inb(@port + 5) & 1
  end

  # Get a charater from the serial.
  # NOTE: If no character is availaible, this will wait until data is received.
  def getc : UInt8
    unless received_data?
    end

    inb(@port)
  end

  def putc(c : UInt8)
    unless transport_empty?
    end

    outb(@port, c)
  end

  private def get_ansi_color(color : Logger::Color) : Int32
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

  def set_color(color : Logger::Color)
    puts "\x1b["
    put_number get_ansi_color(color), 10
    puts "m"
  end
end
