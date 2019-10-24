# Simple module permitting to initialize a class without a heap.
#
# Usage:
# ```
# class Bar
#   include Placement
#
#   def initialize(@name : String)
#   end
#
#   def get_name
#     @name
#   end
# end
#
# bar = uninitialized Bar
# bar.initialize_inplace "Hello from the stack" # => self
# bar.get_name                                  # => "Hello from the stack"
# ```
module Placement
  # The only purpose of this method is to be able to call initialize externally as it's a protected method.
  def initialize_inplace(*args)
    initialize(*args)
    self
  end
end
