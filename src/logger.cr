require "./drivers/serial"

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

  @@type = Type::None

  def self.initialize(type : Type)
    @@type = type
    case type
    when Type::Serial
      Serial.initialize(Serial::COM1)
    else
      Serial.puts "logger setup as None."
    end
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
    else
    end
  end

  def self.message(level : Level, str : String)
    puts "["
    puts prefix(level)
    puts "] "
    puts str
    puts "\n"
  end
end
