struct GDT
  struct Entry
    SIZE = sizeof(Entry)

    @raw_value = 0_u64

    def base_address=(base_address : UInt64)
      @raw_value |= (base_address & 0xFFFF) >> 16 | ((base_address >> 16) & 0xFF) << 32 | ((base_address >> 24) & 0xFF) << 56
    end

    def limit=(limit : UInt64)
      @raw_value |= (limit & 0xFFFF) | ((limit >> 16) & 0xF) << 48
    end

    def privilege_level=(privilege_level : UInt64)
      @raw_value |= (privilege_level & 0xF) << 45
    end

    def set_data_code_type
      @raw_value |= 1_u64 << 44
    end

    # If Data, RW. If Code, RX
    def set_read_write_or_read_execute
      @raw_value |= 1_u64 << 41
    end

    def set_present
      @raw_value |= 1_u64 << 47
    end

    def set_size_enabled
      @raw_value |= 1_u64 << 54
    end

    def set_granuality
      @raw_value |= 1_u64 << 55
    end

    def set_code
      @raw_value |= 1_u64 << 43
    end

    def to_raw
      @raw_value
    end

    def dump
      Serial.puts "GDT::Entry { 0x"
      Serial.put_number(@raw_value, 16)
      Serial.puts " }\n"
    end
  end

  ENTRIES_COUNT = 7

  # This is actually a UInt48 but this is fine (tm)
  @ptr_value = uninitialized UInt64

  @table = uninitialized UInt64[ENTRIES_COUNT]

  def create_entry(base_address : UInt32, limit : UInt32, privilege_level : UInt64, is_code : Bool) : UInt64
    res = Entry.new
    res.base_address = base_address.to_u64
    res.limit = limit.to_u64
    if is_code
      res.set_code
    end
    res.privilege_level = privilege_level
    res.set_granuality
    res.set_size_enabled
    res.set_data_code_type
    res.set_present
    res.set_read_write_or_read_execute

    res.to_raw
  end

  def setup_gdt
    # NULL segment
    @table[0] = 0

    # Kernel Code segment
    @table[1] = create_entry(0, 0xFFFFFFFF, 0, true)

    # Kernel Data segment
    @table[2] = create_entry(0, 0xFFFFFFFF, 0, false)

    # Kernel Stack segment
    @table[3] = create_entry(0, 0xFFFFFFFF, 0, false)

    # Userland Code segment
    @table[4] = create_entry(0, 0xFFFFFFFF, 3, true)

    # Userland Data segment
    @table[5] = create_entry(0, 0xFFFFFFFF, 3, false)

    # Userland Stack segment
    @table[6] = create_entry(0, 0xFFFFFFFF, 3, false)

    @ptr_value = pointerof(@table).address << 16 | (ENTRIES_COUNT * Entry::SIZE - 1)
    Serial.puts "@@ptr_value address { 0x"
    Serial.put_number(pointerof(@ptr_value).address, 16)
    Serial.puts " }\n"
  end

  def flush
    asm("lgdt ($0)" :: "r"(pointerof(@ptr_value)) : "memory")
    asm("
            // Reload CS through far jmp
            ljmp $$0x8, $$reload_CS
            reload_CS:
        ")

    asm("
        # Because it's anoying without this
        .intel_syntax noprefix
        mov ax, 0x10
        mov ds, ax
        mov es, ax
        mov fs, ax
        mov gs, ax
        mov ss, ax
        " :::: "intel")
  end
end
