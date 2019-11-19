abstract struct LoggerDriver
  # Put a given char `c` in the serial transport
  abstract def putc(c : UInt8)

  # Change the current color to a given `color`.
  abstract def set_color(color : Logger::Color)

  # Print a given string.
  def puts(str : String)
    i = 0
    chars = str.to_unsafe
    chars_size = str.bytesize

    raw_puts(chars, chars_size)
  end

  # Print a given raw char array with a given size.
  def raw_puts(chars : UInt8*, chars_size : Int)
    i = 0

    while i < chars_size
      putc(chars[i])
      i += 1
    end
  end

  # Util to print a number on the logger.
  def put_number(value : Int, base, padding = 0, padding_after = false)
    value.internal_to_s(base, false) do |ptr, count|
      if value == 0
        puts "0"
        count += 1
      end

      tmp_count = count

      if !padding_after
        while padding > tmp_count
          puts "0"
          tmp_count += 1
        end
      end

      raw_puts(ptr, count.to_u64)

      if padding_after
        while padding > tmp_count
          puts "0"
          tmp_count += 1
        end
      end
    end
  end
end

require "../drivers/serial"
require "../drivers/vga_text_mode"

module Logger
  # Define the type of the logger to use.
  enum Type
    # All logs goes to the void.
    None = 0
    # All logs goes to the serial.
    Serial
    # All logs goes to the screen.
    Screen
    # All logs goes to all availaibles logger interfaces.
    All
  end

  # Definition of the different levels availaible on thelogger.
  enum Level
    # A Debug log.
    Debug
    # A Warning log.
    Warning
    # An Error log.
    Error
    # An Info log.
    Info
  end

  # Definition of the colors availaible on the logger.
  enum Color : UInt8
    Black         = 0
    Blue
    Green
    Cyan
    Red
    Magenta
    Brown
    Gray
    DarkGray
    BrightBlue
    BrightGreen
    BrightCyan
    BrightRed
    BrightMagenta
    Yellow
    White
  end

  @@type = Type::None
  @@default_color = Color::White

  @@serial_logger = uninitialized Serial
  @@vga_logger = uninitialized VgaTextMode

  # Initialize the logger with the given `Type`.
  def self.initialize(type : Type)
    @@serial_logger = Serial.new
    @@vga_logger = VgaTextMode.new
    @@type = type

    set_color(Color::White)
  end

  # :nodoc:
  def self.serial_logger
    @@serial_logger
  end

  # Log a given `str` with `Level::Debug` level.
  def self.debug(str : String, line_break : Bool = true)
    message(Level::Debug, str, line_break)
  end

  # Log a given `str` with `Level::Warning` level.
  def self.warn(str : String, line_break : Bool = true)
    message(Level::Warning, str, line_break)
  end

  # Log a given `str` with `Level::Error` level.
  def self.error(str : String, line_break : Bool = true)
    message(Level::Error, str, line_break)
  end

  # Log a given `str` with `Level::Info` level.
  def self.info(str : String, line_break : Bool = true)
    message(Level::Info, str, line_break)
  end

  private def self.prefix(level : Level) : String
    case level
    when Level::Debug
      "debug"
    when Level::Warning
      "warn"
    when Level::Error
      "error"
    when Level::Info
      "info"
    else
      "unknown level"
    end
  end

  # Print a given string.
  def self.puts(str : String)
    case @@type
    when Type::Serial
      @@serial_logger.puts str
    when Type::Screen
      @@vga_logger.puts str
    when Type::All
      @@serial_logger.puts str
      @@vga_logger.puts str
    else
      # No operations
    end
  end

  # Print a given raw char array with a given size.
  def self.raw_puts(chars : UInt8*, chars_size : Int)
    case @@type
    when Type::Serial
      @@serial_logger.raw_puts chars, chars_size
    when Type::Screen
      @@vga_logger.raw_puts chars, chars_size
    when Type::All
      @@serial_logger.raw_puts chars, chars_size
      @@vga_logger.raw_puts chars, chars_size
    else
      # No operations
    end
  end

  # Util to print a number on the logger.
  def self.put_number(value : Int, base, padding = 0, padding_after = false)
    case @@type
    when Type::Serial
      @@serial_logger.put_number value, base, padding, padding_after
    when Type::Screen
      @@vga_logger.put_number value, base, padding, padding_after
    when Type::All
      @@serial_logger.put_number value, base, padding, padding_after
      @@vga_logger.put_number value, base, padding, padding_after
    else
      # No operations
    end
  end

  # Print the given range in hexadecimal following xdd output.
  def self.print_hex(pointer : UInt8*, size : Int)
    print_hex_with_address(pointer, size, pointer.address)
  end

  # Print the given range in hexadecimal following xdd output with a custom `display_address`.
  def self.print_hex_with_address(pointer : UInt8*, size : Int, display_address : UInt64)
    line_content = uninitialized UInt8[0x10]
    last_content_index = 0

    size.times do |i|
      content_index = i.remainder(line_content.size)

      # line_content is full and ready to be printed
      if last_content_index > content_index
        put_number display_address + i, 16, 8
        puts ": "

        line_content.size.times do |i|
          put_number line_content[i], 16, 2
          if i.remainder(2) == 1
            puts " "
          end
        end

        puts "\n"
      end

      line_content[content_index] = pointer[i]

      last_content_index = content_index
    end

    # If the loop ended while not printing the last line, make sure to do so
    if last_content_index != line_content.size - 1
      put_number display_address + (size & (0 - line_content.size)).to_u64, 16, 8
      puts ": "

      line_content.size.times do |i|
        if i > last_content_index
          line_content[i] = 0
        end

        put_number line_content[i], 16, 8
        if i.remainder(2) == 1
          puts " "
        end
      end
      puts "\n"
    end
  end

  # Print the given range in binary following xdd output.
  def self.print_bin(pointer : UInt8*, size : Int)
    print_bin_with_address(pointer, size, pointer.address)
  end

  # Print the given range in binary following xdd output with a custom `display_address`.
  def self.print_bin_with_address(pointer : UInt8*, size : Int, display_address : UInt64)
    line_content = uninitialized UInt8[4]
    last_content_index = 0

    size.times do |i|
      content_index = i.remainder(line_content.size)

      # line_content is full and ready to be printed
      if last_content_index > content_index
        put_number display_address + i, 16, 8
        puts ": "

        line_content.size.times do |i|
          put_number(line_content[i], 2, 8, true)
          puts " "
        end

        puts "\n"
      end

      line_content[content_index] = pointer[i]

      last_content_index = content_index

      content_index += 1
    end

    # If the loop ended while not printing the last line, make sure to do so
    if last_content_index != line_content.size
      put_number display_address + (size & (0 - line_content.size)).to_u64, 16, 8
      puts ": "

      line_content.size.times do |i|
        if i > last_content_index
          line_content[i] = 0
        end

        put_number(line_content[i], 2, 8, true)
        puts " "
      end
      puts "\n"
    end
  end

  private def self.set_default_color(color : Color)
    @@default_color = color
  end

  private def self.reset_color
    set_color(@@default_color)
  end

  private def self.set_color(level : Level)
    color = case level
            when Level::Debug
              Color::DarkGray
            when Level::Warning
              Color::Yellow
            when Level::Error
              Color::Red
            when Level::Info
              Color::Cyan
            else
              Color::Gray
            end

    set_color(color)
  end

  private def self.set_color(color : Color)
    case @@type
    when Type::Serial
      @@serial_logger.set_color color
    when Type::Screen
      @@vga_logger.set_color color
    when Type::All
      @@serial_logger.set_color color
      @@vga_logger.set_color color
    else
      # No operations
    end
  end

  # Log a given `str` with the given `level`.
  def self.message(level : Level, str : String, line_break : Bool = true)
    puts "["
    set_color level
    puts prefix(level)
    reset_color
    puts "] "
    puts str

    if line_break
      puts "\n"
    end
  end
end
