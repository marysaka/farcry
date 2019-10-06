# Simple UART implementation
module Serial
    COM1 = 0x3F8_u16

    @@port: UInt16 = 0

    def self.initialize(port : UInt16)
        @@port = port
    end

    def self.transport_empty? : Bool
        false
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
            i += 1;
        end
    end

    def self.put_number(value : Int, base)
        value.internal_to_s(base, false) do |ptr, count|
            raw_puts(ptr, count.to_u64)
        end
    end
end