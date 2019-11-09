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

    # Custom
    define_bit reserved_space, 9

    def address=(address : UInt32)
      @value = address | @value
    end

    def address
      @value >> 12 << 12
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
      result = Memory::PhysicalAllocator.allocate(Memory::PAGE_SIZE)
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

    def enable_paging
      @entries = Pointer(PageDirectoryEntry).new PAGE_DIRECTORY_PAGE.to_u64
      ::enable_paging(@entries_physical.as(Void*))
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

    private def create_page_table(address : UInt32) : Pointer(PageDirectoryEntry) | Memory::Error
      result = Memory::PhysicalAllocator.allocate(Memory::PAGE_SIZE)
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
          page_table.value.user_accesible = true
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
          Logger.put_number address, 16
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
        # Logger.debug "Creating page table at address 0x", false
        # Logger.put_number address.to_u32 >> 22 << 22, 16
        # Logger.puts "\n"

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

    private def is_present(address : UInt32) : Bool
      page_table = get_page_table address
      if page_table.nil?
        return false
      end

      page_table_entry = page_table.value.get_table_entry address, is_paging_on

      !page_table_entry.nil?
    end

    private def is_reserved(address : UInt32) : Bool
      page_table = get_page_table address
      if page_table.nil?
        return false
      end

      page_table_entry = page_table.value.get_table_entry address, is_paging_on, false

      if page_table_entry.nil?
        panic("impossible")
      end

      page_table_entry.value.reserved_space?
    end

    private def is_present_range(address : UInt32, size : UInt32) : Bool
      page_count = size / Memory::PAGE_SIZE

      page_count.times do |page_index|
        if is_present(address + page_index * Memory::PAGE_SIZE)
          return true
        end
      end

      false
    end

    private def is_reserved_range(address : UInt32, size : UInt32) : Bool
      page_count = size / Memory::PAGE_SIZE

      page_count.times do |page_index|
        if is_reserved(address + page_index * Memory::PAGE_SIZE)
          return true
        end
      end

      false
    end

    private def reserve_page(virtual_address : UInt32) : Nil | Memory::Error
      if virtual_address % Memory::PAGE_SIZE != 0
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

        table_entry.value.reserved_space = true

        flush

        nil
      when Memory::Error
        return page_table
      else
        panic("Unknown return from get_or_create_page_table!")
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

        # Logger.debug "Mapped physical address 0x", false
        # Logger.put_number physical_address.to_u32, 16
        # Logger.puts " to virtual address 0x"
        # Logger.put_number virtual_address.to_u32, 16
        # Logger.puts "\n"

        nil
      when Memory::Error
        return page_table
      else
        panic("Unknown return from get_or_create_page_table!")
      end
    end

    def unmap_page(virtual_address : UInt32, free_physical_frame = true) : Nil | Memory::Error
      if virtual_address % Memory::PAGE_SIZE != 0
        return Memory::Error::InvalidAddress
      end

      page_table = get_page_table virtual_address

      case page_table
      when Pointer(PageDirectoryEntry)
        table_entry = page_table.value.get_table_entry virtual_address, is_paging_on, false

        if table_entry.nil?
          panic("Brace yourself, the impossible has happened!")
        end

        if !table_entry.value.present?
          Logger.error "Page entry at address ", false
          Logger.put_number virtual_address.to_u32, 16
          Logger.puts " is not in used!\n"

          panic("Trying to unmap a not mapped page!")
        end

        physical_address = table_entry.value.address

        table_entry.value.present = false
        flush

        # Logger.debug "Unmapping physical address 0x", false
        # Logger.put_number physical_address.to_u32, 16
        # Logger.puts " to virtual address 0x"
        # Logger.put_number virtual_address.to_u32, 16
        # Logger.puts "\n"

        if free_physical_frame
          return Memory::PhysicalAllocator.free(physical_address, Memory::PAGE_SIZE)
        end

        nil
      when Memory::Error
        panic("Error while trying to unmap a page!")
      else
        panic("Trying to unmap a not mapped page!")
      end
    end

    private def allocate_pages(virtual_address : UInt32, size : UInt32, permissions : Memory::Permissions, user_accesible : Bool) : Pointer(Void) | Memory::Error
      if virtual_address % Memory::PAGE_SIZE != 0
        return Memory::Error::InvalidAddress
      end

      if size % Memory::PAGE_SIZE != 0
        return Memory::Error::InvalidSize
      end

      page_index = 0_u32

      error = Memory::PhysicalAllocator.allocate_non_contiguous(size) do |physical_address|
        res = map_page(physical_address, virtual_address + page_index * Memory::PAGE_SIZE, permissions, user_accesible)

        if !res.nil?
          panic("allocate: Invalid argument sent to map_page")
        end

        page_index += 1
      end

      if !error.nil?
        return error
      end

      Pointer(Void).new virtual_address.to_u64
    end

    private def find_contigous_space(size : UInt32) : UInt32 | Memory::Error
      target_address = nil
      tmp_size = size

      tmp_address = 0_u32

      while tmp_size > 0
        if is_present(tmp_address) || is_reserved(tmp_address)
          tmp_size = size
          target_address = nil
        else
          if target_address.nil?
            target_address = tmp_address
          end

          tmp_size -= Memory::PAGE_SIZE
        end

        # That was the last page
        break if tmp_address == Memory::LAST_PAGE_ADDRESS

        tmp_address += Memory::PAGE_SIZE
      end

      if tmp_size != 0 || target_address.nil?
        return Memory::Error::OutOfMemory
      end

      target_address
    end

    def reserve_space(size : UInt32) : UInt32 | Memory::Error
      if size % Memory::PAGE_SIZE != 0
        return Memory::Error::InvalidSize
      end

      result_address = find_contigous_space(size)

      case result_address
      when UInt32
        Logger.info "Found availaible virtual space at 0x", false
        Logger.put_number result_address, 16
        Logger.puts "\n"

        page_count = size / Memory::PAGE_SIZE
        i = 0
        while i < page_count
          target_address = result_address + i * Memory::PAGE_SIZE

          result = reserve_page(target_address)

          if !result.nil?
            Logger.error "Cannot free: ", false
            Logger.put_number result.to_u32, 16
            Logger.puts "\n"
            panic("unmap_page failed!")
          end
          i += 1
        end

        result_address
      else
        return Memory::Error::OutOfMemory
      end
    end

    def allocate_for_reserved_space(virtual_address : UInt32, size : UInt32, permissions : Memory::Permissions, user_accesible : Bool) : Pointer(Void) | Memory::Error
      if size % Memory::PAGE_SIZE != 0
        return Memory::Error::InvalidSize
      end

      if virtual_address % Memory::PAGE_SIZE != 0
        return Memory::Error::InvalidAddress
      end

      if !is_reserved_range(virtual_address, size) || is_present_range(virtual_address, size)
        return Memory::Error::InvalidAddress
      end

      allocate_pages(virtual_address, size, permissions, user_accesible)
    end

    def allocate(size : UInt32, permissions : Memory::Permissions, user_accesible : Bool) : Pointer(Void) | Memory::Error
      if size % Memory::PAGE_SIZE != 0
        return Memory::Error::InvalidSize
      end

      target_address = find_contigous_space(size)

      case target_address
      when UInt32
        Logger.info "Found availaible virtual space at 0x", false
        Logger.put_number target_address, 16
        Logger.puts "\n"

        allocate_pages(target_address, size, permissions, user_accesible)
      else
        return Memory::Error::OutOfMemory
      end
    end

    def free(address : UInt32, size : UInt32) : Nil | Memory::Error
      if address % Memory::PAGE_SIZE != 0
        return Memory::Error::InvalidAddress
      end

      if size % Memory::PAGE_SIZE != 0
        return Memory::Error::InvalidSize
      end

      page_count = size / Memory::PAGE_SIZE
      i = 0
      while i < page_count
        target_address = address + i * Memory::PAGE_SIZE

        result = unmap_page(target_address)

        if !result.nil?
          Logger.error "Cannot free: ", false
          Logger.put_number result.to_u32, 16
          Logger.puts "\n"
          panic("unmap_page failed!")
        end
        i += 1
      end
    end

    def flush
      flush_tlb
    end
  end
end
