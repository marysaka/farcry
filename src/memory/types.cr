module Memory
  PAGE_SIZE = 0x1000_u32

  LAST_PAGE_ADDRESS = UInt32::MAX >> 12 << 12

  enum Error : UInt8
    InvalidAddress
    InvalidSize
    OutOfMemory
    StateMismatch
  end

  @[Flags]
  enum Permissions
    Read
    Write
    Execute
  end
end
