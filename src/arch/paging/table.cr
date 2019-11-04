require "../../memory/**"

macro define_bit(name, bit)
  def {{name}}?
    @value.bit({{bit}}) == 1
  end

  def {{name}}=(activate : Bool)
    if activate
      @value |= 1_u64 << {{bit}}
    else
      @value &= ~(1_u64 << {{bit}})
    end
  end
end

module Arch::Paging
  struct PageDirectoryEntry
    @value : UInt32 = 0

    define_bit present, 0
    define_bit read_write, 1
    define_bit user_accesible, 2
    define_bit write_mode, 3
    define_bit no_cache, 4
    define_bit accessed, 5
    define_bit large_page, 7
    define_bit global, 8

    def address=(address : UInt32)
      @value = address | @value
    end

    def address
      @value & ~((1 << 12) - 1)
    end

    def get_table_entry(address : UInt32, is_paging_on : Bool, must_be_present = true) : Pointer(PageTableEntry) | Nil
      page_index = (address >> 12) & 0x3FF
      table_index = (address >> 22) & 0x3FF

      if is_paging_on
        target_page_entry_address = (PageDirectory::PAGE_DIRECTORY_BASE + table_index * Memory::PAGE_SIZE).to_u64
      else
        target_page_entry_address = address().to_u64
      end

      result = Pointer(PageTableEntry).new(target_page_entry_address)
      result += page_index

      if result.value.present? || !must_be_present
        return result
      end
      nil
    end

    def dump
      Logger.print_bin(pointerof(@value), 0x4)
    end
  end

  struct PageTableEntry
    @value : UInt32 = 0

    define_bit present, 0
    define_bit read_write, 1
    define_bit user_accesible, 2
    define_bit write_mode, 3
    define_bit no_cache, 4
    define_bit accessed, 5

    def address=(address : UInt32)
      @value = address | @value
    end

    def address
      @value & ~((1 << 12) - 1)
    end

    def dump
      ptr = pointerof(@value)
      Logger.error "PageTableEntry {\naddress: 0x", false
      Logger.put_number ptr.address, 16, 8
      Logger.puts ", dump: 0x"
      Logger.put_number @value, 16, 8
      Logger.puts "\n}\n"
    end
  end

  struct PageDirectory
    # hardcoded value to do a recursive mapping
    PAGE_DIRECTORY_BASE = 0xffc00000_u32
    PAGE_DIRECTORY_PAGE = 0xfffff000_u32
    @entries = Pointer(PageDirectoryEntry).new 0
    @entries_physical = Pointer(PageDirectoryEntry).new 0

    def initialize
      result = Memory::PhysicalAllocator.allocate_pages(Memory::PAGE_SIZE)
      case result
      when Pointer(Void)
        @entries = result.as(Pointer(PageDirectoryEntry))
        @entries_physical = @entries

        memset(@entries.as(UInt8*), 0, Memory::PAGE_SIZE)

        page_table = get_page_table PAGE_DIRECTORY_PAGE, false
        case page_table
        when Pointer(PageDirectoryEntry)
          page_table.value.address = result.address.to_u32
          page_table.value.write_mode = false
          page_table.value.no_cache = false
          page_table.value.large_page = false
          page_table.value.global = false
          page_table.value.present = true
          page_table.value.read_write = true

          flush
        else
          panic("Recursive page table already in use during creation!")
        end
      when Memory::Error
        Logger.error "Cannot allocate page directory: ", false
        Logger.put_number result.to_u32, 16
        Logger.puts "\n"
        panic "Cannot allocate page directory"
      end
    end

    private def is_paging_on
      # TOOD: detect that with cr3
      @entries.address != @entries_physical.address
    end

    private def get_page_table(address : UInt32, must_be_present = true) : Pointer(PageDirectoryEntry) | Nil
      page_directory_index = (address >> 22) & 0x3FF

      page_table = @entries
      page_table += page_directory_index

      if page_table.value.present? || !must_be_present
        return page_table
      end
      nil
    end

    def create_page_table(address : UInt32) : Pointer(PageDirectoryEntry) | Memory::Error
      result = Memory::PhysicalAllocator.allocate_pages(Memory::PAGE_SIZE)
      case result
      when Pointer(Void)
        # First of all, we get the page table
        page_table = get_page_table address, false
        case page_table
        when Pointer(PageDirectoryEntry)
          # We setup it
          page_table.value.address = result.address.to_u32
          page_table.value.write_mode = false
          page_table.value.no_cache = false
          page_table.value.large_page = false
          page_table.value.global = false
          page_table.value.present = true
          page_table.value.read_write = true

          # Flush the TLB
          flush_tlb

          # now the page should be mapped in the recursive mapping!
          # So we can just get the first entry and clean the whole table again and flush the tlb once more to be sure we don't have garbage mapping.
          page_table_first_entry = page_table.value.get_table_entry address >> 22 << 22, is_paging_on, false

          if page_table_first_entry.nil?
            panic("page_table_first_entry is nil (impossible)")
          else
            memset(page_table_first_entry.as(UInt8*), 0, Memory::PAGE_SIZE)
          end

          # Flush the TLB
          flush_tlb
          return page_table
        else
          Logger.error "Page table at address ", false
          Logger.put_number address.to_u32, 16
          Logger.puts " is already used!\n"

          panic("Page table already in use during creation!")
        end
      when Memory::Error
        Logger.error "Cannot allocate page directory: ", false
        Logger.put_number result.to_u32, 16
        Logger.puts "\n"
        return Memory::Error::OutOfMemory
      else
        panic("Unknown return from allocate_pages!")
      end
    end

    private def get_or_create_page_table(address : UInt32) : Pointer(PageDirectoryEntry) | Memory::Error
      page_table = get_page_table address

      if page_table.nil?
        Logger.debug "Creating page table at address 0x", false
        Logger.put_number address.to_u32 >> 22 << 22, 16
        Logger.puts "\n"

        page_table = create_page_table(address)
      end

      page_table
    end

    def identity_map_pages(address : UInt32, size : UInt32, permissions : Memory::Permissions, user_accesible : Bool, physcial_frames_already_allocated = false) : Nil | Memory::Error
      if address % Memory::PAGE_SIZE != 0
        return Memory::Error::InvalidAddress
      end

      if size % Memory::PAGE_SIZE != 0
        return Memory::Error::InvalidSize
      end

      if !physcial_frames_already_allocated
        result = Memory::PhysicalAllocator.set_page_range_state(address, size, true)
        case result
        when Memory::Error
          return result
        end
      end

      page_count = size / Memory::PAGE_SIZE
      i = 0
      while i < page_count
        target_address = address + i * Memory::PAGE_SIZE
        case map_page(target_address, target_address, permissions, user_accesible)
        when Memory::Error
          panic("Identity mapping failed!")
        end
        i += 1
      end

      nil
    end

    def map_page_ranges(physical_address : UInt32, virtual_address : UInt32, size : UInt32, permissions : Memory::Permissions, user_accesible : Bool) : Nil | Memory::Error
      if physical_address % Memory::PAGE_SIZE != 0 || virtual_address % Memory::PAGE_SIZE != 0
        return Memory::Error::InvalidAddress
      end

      if size % Memory::PAGE_SIZE != 0
        return Memory::Error::InvalidSize
      end

      (size / Memory::PAGE_SIZE).times do |i|
        map_page(physical_address + i * Memory::PAGE_SIZE, virtual_address + i * Memory::PAGE_SIZE, permissions, user_accesible)
      end
    end

    def map_page(physical_address : UInt32, virtual_address : UInt32, permissions : Memory::Permissions, user_accesible : Bool) : Nil | Memory::Error
      if physical_address % Memory::PAGE_SIZE != 0 || virtual_address % Memory::PAGE_SIZE != 0
        return Memory::Error::InvalidAddress
      end

      page_table = get_or_create_page_table virtual_address

      case page_table
      when Pointer(PageDirectoryEntry)
        table_entry = page_table.value.get_table_entry virtual_address, is_paging_on, false

        if table_entry.nil? || table_entry.value.present?
          Logger.error "Page entry at address ", false
          Logger.put_number virtual_address.to_u32, 16
          Logger.puts " is already used!\n"

          panic("Page entry already in use during map_page!")
        end

        table_entry.value.read_write = (permissions & (Memory::Permissions::Read | Memory::Permissions::Write)) != 0
        table_entry.value.address = physical_address
        table_entry.value.no_cache = false
        table_entry.value.write_mode = false
        table_entry.value.user_accesible = user_accesible
        table_entry.value.present = true

        flush

        nil
      when Memory::Error
        return page_table
      else
        panic("Unknown return from get_or_create_page_table!")
      end
    end

    def allocate_pages(size : UInt32) : Pointer(Void) | Memory::Error
      Memory::Error::OutOfMemory
    end

    def flush
      flush_tlb
    end

    def enable_paging
      @entries = Pointer(PageDirectoryEntry).new PAGE_DIRECTORY_PAGE.to_u64
      ::enable_paging(@entries_physical.as(Void*))
    end
  end
end
