class String
    def to_unsafe : UInt8*
        pointerof(@c)
    end

    def size
        @length
    end

    def bytesize
        @bytesize
    end
end

struct Pointer(T)
    def [](offset)
      (self + offset).value
    end
  
    def []=(offset, value : T)
      (self + offset).value = value
    end
  
    def +(other : Int)
      self + other.to_i64
    end
  
    def +(other : Nil)
      self
    end
end
