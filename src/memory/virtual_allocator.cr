require "./types"

struct SinglyLinkedList(T)
    @data : T
    @next : Pointer(SinglyLinkedList(T))

    def initialize(@data, @next = Pointer(SinglyLinkedList(T)).new(0))
    end

    property data
    property "next"
end

module Memory::VirtualAllocator

end