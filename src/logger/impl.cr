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

  def self.debug(str : String)
    message(Level::Debug, str)
  end

  def self.warn(str : String)
    message(Level::Warning, str)
  end

  def self.error(str : String)
    message(Level::Error, str)
  end

  def self.info(str : String)
    message(Level::Info, str)
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

  private def self.puts(str : String)
    case @@type
    when Type::Serial
      Serial.puts str
    when Type::Screen
      VgaTextMode.puts str
    else
      # No operations
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

  def self.message(level : Level, str : String)
    puts "["
    set_color level
    puts prefix(level)
    reset_color
    puts "] "
    puts str
    puts "\n"
  end
end
