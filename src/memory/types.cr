module Memory
  PAGE_SIZE = 0x1000
  enum Error : UInt8
    InvalidAddress
    InvalidSize
    OutOfMemory
    StateMismatch
  end
end
