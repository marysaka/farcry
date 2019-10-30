module Memory
  PAGE_SIZE = 0x1000_u32
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
