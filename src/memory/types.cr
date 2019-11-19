module Memory
  # The granuality of a page.
  PAGE_GRANUALITY = 12_u32

  # The size of a page.
  PAGE_SIZE = 1_u32 << PAGE_GRANUALITY

  # The last page availaible on the address space.
  LAST_PAGE_ADDRESS = UInt32::MAX >> PAGE_GRANUALITY << PAGE_GRANUALITY

  # Represent a memory error in the physical and virtual allocator.
  enum Error : UInt8
    # The input address is invalid.
    InvalidAddress
    # The input size is invalid.
    InvalidSize
    # The allocator couldn't allocate memory (memory exhaustion)
    OutOfMemory

    # There is an internal state mismatch
    # FIXME: This should maybe not be exposed?
    StateMismatch
  end

  # Represent the permissions attached to a memory range.
  @[Flags]
  enum Permissions
    # The memory is readable.
    Read
    # The memory is writable.
    Write
    # The memory is executable.
    # NOTE: Right now, PAE isn't activated so this is a no op.
    Execute
  end
end
