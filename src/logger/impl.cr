require "../drivers/serial"
require "../drivers/vga_text_mode"

module Logger
  enum Type
    None
    Serial
    Screen
  end

  enum Level
    Debug
    Warning
    Error
    Info
  end

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

  def self.initialize(type : Type)
    @@type = type
    case type
    when Type::Serial
      Serial.initialize(Serial::COM1)
    when Type::Screen
      VgaTextMode.initialize
    else
      Serial.puts "logger setup as None."
    end

    set_color(Color::White)
  end

  def self.debug(str : String, line_break : Bool = true)
    message(Level::Debug, str, line_break)
  end

  def self.warn(str : String, line_break : Bool = true)
    message(Level::Warning, str, line_break)
  end

  def self.error(str : String, line_break : Bool = true)
    message(Level::Error, str, line_break)
  end

  def self.info(str : String, line_break : Bool = true)
    message(Level::Info, str, line_break)
  end

  def self.prefix(level : Level) : String
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

  def self.puts(str : String)
    case @@type
    when Type::Serial
      Serial.puts str
    when Type::Screen
      VgaTextMode.puts str
    else
      # No operations
    end
  end

  def self.put_number(value : Int, base, padding = 0)
    case @@type
    when Type::Serial
      Serial.put_number value, base, padding
    when Type::Screen
      VgaTextMode.put_number value, base, padding
    else
      # No operations
    end
  end

  def self.print_hex(pointer : UInt8*, size : Int)
    print_hex_with_address(pointer, size, pointer.address)
  end

  def self.print_hex_with_address(pointer : UInt8*, size : Int, display_address : UInt64)
    line_content = uninitialized UInt8[0x10]
    last_content_index = 0

    size.times do |i|
      content_index = i.remainder(line_content.size)

      # line_content is full and ready to be printed
      if last_content_index > content_index
        put_number pointer.address + i, 16, 8
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
      put_number pointer.address + (size & (0 - line_content.size)).to_u64, 16, 8
      puts ": "

      line_content.size.times do |i|
        if i > last_content_index
          line_content[i] = 0
        end

        put_number line_content[i], 16, 2
        if i.remainder(2) == 1
          puts " "
        end
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
      Serial.set_color color
    when Type::Screen
      VgaTextMode.set_color color
    else
      # No operations
    end
  end

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