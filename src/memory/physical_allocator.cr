require "./types"

lib LinkerScript
  $kernel_start = KERNEL_START : UInt8
  $kernel_end = KERNEL_END : UInt8
end

module Memory::PhysicalAllocator
  BITMAP_ELEMENT_SIZE = sizeof(UInt32)
  @@bit_map = uninitialized StaticArray(UInt32, 0x8000)

  struct Status
    property free_pages : UInt32
    property total_pages : UInt32

    def initialize(@free_pages, @total_pages)
    end
  end

  def self.initialize
    # zeroed the bit_map
    memset(Pointer(UInt8).new(pointerof(@@bit_map).address), 0, sizeof(typeof(@@bit_map)).to_u32)

    kernel_start = pointerof(LinkerScript.kernel_start).address.to_u32
    kernel_end = pointerof(LinkerScript.kernel_end).address.to_u32

    Logger.debug "physical kernel range size: [0x", false
    Logger.put_number kernel_start, 16
    Logger.puts " - 0x"
    Logger.put_number kernel_end, 16
    Logger.puts "]\n"

    reserve_result = set_page_range_state(kernel_start, kernel_end - kernel_start, true)

    # Test
    case reserve_result
    when Pointer(Void)
      Logger.info "physical kernel reservation done"
    when Error
      Logger.error "Cannot reserve: ", false
      Logger.put_number reserve_result.to_u32, 16
      Logger.puts "\n"
      panic("Cannot do physical kernel reservation")
    end
  end

  def self.dump(limit = UInt32::MAX)
    map_index = (limit >> 12) / 8
    Logger.print_hex_with_address(Pointer(UInt8).new(pointerof(@@bit_map).address), map_index.to_u32, 0x0)
  end

  private def self.is_reserved(address : UInt32) : Bool
    tmp = address >> 12
    map_index = tmp / (BITMAP_ELEMENT_SIZE * 8)
    bit_index = tmp % (BITMAP_ELEMENT_SIZE * 8)

    @@bit_map[map_index].bit(bit_index) == 1
  end

  private def self.is_reserved_range(address : UInt32, size : UInt32) : Bool
    page_count = size / PAGE_SIZE

    page_count.times do |page_index|
      if is_reserved(address + page_index * PAGE_SIZE)
        return true
      end
    end

    false
  end

  def self.set_page_range_state(address : UInt32, size : UInt32, is_used : Bool) : Pointer(Void) | Error
    if address % PAGE_SIZE != 0
      return Error::InvalidAddress
    end

    if size % PAGE_SIZE != 0
      return Error::InvalidSize
    end

    if is_reserved_range(address, size) == is_used
      return Error::StateMismatch
    end

    base_page_index = address >> 12
    page_count = size / PAGE_SIZE

    page_count.times do |page_index|
      tmp = base_page_index + page_index
      map_index = tmp / (BITMAP_ELEMENT_SIZE * 8)
      bit_index = tmp % (BITMAP_ELEMENT_SIZE * 8)

      if is_used
        @@bit_map[map_index] |= 1 << bit_index
      else
        @@bit_map[map_index] &= ~(1 << bit_index)
      end
    end

    Pointer(Void).new address.to_u64
  end

  def self.get_status : Status
    address = 0_u32

    free_pages = 0_u32
    total_pages = 0_u32

    while true
      if !is_reserved(address)
        free_pages += 1
      end

      total_pages += 1

      break if address == LAST_PAGE_ADDRESS
      address += PAGE_SIZE
    end
    Status.new(free_pages, total_pages)
  end

  def self.allocate(size : UInt32) : Pointer(Void) | Error
    if size % PAGE_SIZE != 0
      return Error::InvalidSize
    end

    target_address = nil
    tmp_size = size

    tmp_address = 0_u32

    while tmp_size > 0
      if is_reserved(tmp_address)
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

    if tmp_size != 0
      return Error::OutOfMemory
    end

    case target_address
    when UInt32
      Logger.info "Allocated physical page at 0x", false
      Logger.put_number target_address, 16
      Logger.puts "\n"
      set_page_range_state(target_address, size, true)
    else
      return Error::OutOfMemory
    end
  end

  def self.allocate_non_contiguous(size : UInt32) : Nil | Error
    page_count = size / Memory::PAGE_SIZE

    status = get_status
    case status
    when Status
      if status.free_pages < page_count
        return Memory::Error::OutOfMemory
      end

      target_address = nil
      tmp_size = size

      tmp_address = 0_u32

      while tmp_size > 0
        if !is_reserved(tmp_address)
          yield tmp_address

          tmp_size -= PAGE_SIZE
        end

        # That was the last page
        break if tmp_address == LAST_PAGE_ADDRESS

        tmp_address += PAGE_SIZE
      end

      # If we don't have memory left at this point, as we checked the status before, this is a TOCTOU, we panic.
      if tmp_size != 0
        panic("TOCTOU in allocate_non_contiguous")
      end

      nil
    else
      return status
    end
  end

  def self.free(address : UInt32, size : UInt32) : Nil | Error
    set_page_range_state(address, size, false)
  end
end
