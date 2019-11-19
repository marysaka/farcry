# `Object` is the base type of all Crystal objects.
class Object
  # Returns `true` if this object is equal to *other*.
  #
  # Subclasses override this method to provide class-specific meaning.
  abstract def ==(other)

  # Returns `true` if this object is not equal to *other*.
  #
  # By default this method is implemented as `!(self == other)`
  # so there's no need to override this unless there's a more efficient
  # way to do it.
  def !=(other)
    !(self == other)
  end

  # Shortcut to `!(self =~ other)`.
  def !~(other)
    !(self =~ other)
  end

  # Case equality.
  #
  # The `===` method is used in a `case ... when ... end` expression.
  #
  # For example, this code:
  #
  # ```
  # case value
  # when x
  #   # something when x
  # when y
  #   # something when y
  # end
  # ```
  #
  # Is equivalent to this code:
  #
  # ```
  # if x === value
  #   # something when x
  # elsif y === value
  #   # something when y
  # end
  # ```
  #
  # Object simply implements `===` by invoking `==`, but subclasses
  # (notably `Regex`) can override it to provide meaningful case-equality semantics.
  def ===(other)
    self == other
  end

  # Pattern match.
  #
  # Overridden by descendants (notably `Regex` and `String`) to provide meaningful
  # pattern-match semantics.
  def =~(other)
    nil
  end

  # Appends this object's value to *hasher*, and returns the modified *hasher*.
  #
  # Usually the macro `def_hash` can be used to generate this method.
  # Otherwise, invoke `hash(hasher)` on each object's instance variables to
  # accumulate the result:
  #
  # ```
  # def hash(hasher)
  #   hasher = @some_ivar.hash(hasher)
  #   hasher = @some_other_ivar.hash(hasher)
  #   hasher
  # end
  # ```
  abstract def hash(hasher)

  # Generates an `UInt64` hash value for this object.
  #
  # This method must have the property that `a == b` implies `a.hash == b.hash`.
  #
  # The hash value is used along with `==` by the `Hash` class to determine if two objects
  # reference the same hash key.
  #
  # Subclasses must not override this method. Instead, they must define `hash(hasher)`,
  # though usually the macro `def_hash` can be used to generate this method.
  def hash
    hash(Crystal::Hasher.new).result
  end

  # Yields `self` to the block, and then returns `self`.
  #
  # The primary purpose of this method is to "tap into" a method chain,
  # in order to perform operations on intermediate results within the chain.
  #
  # ```
  # (1..10).tap { |x| puts "original: #{x.inspect}" }
  #   .to_a.tap { |x| puts "array: #{x.inspect}" }
  #   .select { |x| x % 2 == 0 }.tap { |x| puts "evens: #{x.inspect}" }
  #   .map { |x| x*x }.tap { |x| puts "squares: #{x.inspect}" }
  # ```
  def tap
    yield self
    self
  end

  # Yields `self`. `Nil` overrides this method and doesn't yield.
  #
  # This method is useful for dealing with nilable types, to safely
  # perform operations only when the value is not `nil`.
  #
  # ```
  # # First program argument in downcase, or nil
  # ARGV[0]?.try &.downcase
  # ```
  def try
    yield self
  end

  # Returns `self`.
  # `Nil` overrides this method and raises `NilAssertionError`, see `Nil#not_nil!`.
  def not_nil!
    self
  end

  # Returns `self`.
  #
  # ```
  # str = "hello"
  # str.itself.object_id == str.object_id # => true
  # ```
  def itself
    self
  end

  # Unsafely reinterprets the bytes of an object as being of another `type`.
  #
  # This method is useful to treat a type that is represented as a chunk of
  # bytes as another type where those bytes convey useful information. As an
  # example, you can check the individual bytes of an `Int32`:
  #
  # ```
  # 0x01020304.unsafe_as(StaticArray(UInt8, 4)) # => StaticArray[4, 3, 2, 1]
  # ```
  #
  # Or treat the bytes of a `Float64` as an `Int64`:
  #
  # ```
  # 1.234_f64.unsafe_as(Int64) # => 4608236261112822104
  # ```
  #
  # This method is **unsafe** because it behaves unpredictably when the given
  # `type` doesn't have the same bytesize as the receiver, or when the given
  # `type` representation doesn't semantically match the underlying bytes.
  #
  # Also note that because `unsafe_as` is a regular method, unlike the pseudo-method
  # `as`, you can't specify some types in the type grammar using a short notation, so
  # specifying a static array must always be done as `StaticArray(T, N)`, a tuple
  # as `Tuple(...)` and so on, never as `UInt8[4]` or `{Int32, Int32}`.
  def unsafe_as(type : T.class) forall T
    x = self
    pointerof(x).as(T*).value
  end

  {% for prefixes in { {"", "", "@"}, {"class_", "self.", "@@"} } %}
    {%
      macro_prefix = prefixes[0].id
      method_prefix = prefixes[1].id
      var_prefix = prefixes[2].id
    %}

    # Defines getter methods for each of the given arguments.
    #
    # Writing:
    #
    # ```
    # class Person
    #   {{macro_prefix}}getter name
    # end
    # ```
    #
    # Is the same as writing:
    #
    # ```
    # class Person
    #   def {{method_prefix}}name
    #     {{var_prefix}}name
    #   end
    # end
    # ```
    #
    # The arguments can be string literals, symbol literals or plain names:
    #
    # ```
    # class Person
    #   {{macro_prefix}}getter :name, "age"
    # end
    # ```
    #
    # If a type declaration is given, a variable with that name
    # is declared with that type.
    #
    # ```
    # class Person
    #   {{macro_prefix}}getter name : String
    # end
    # ```
    #
    # Is the same as writing:
    #
    # ```
    # class Person
    #   {{var_prefix}}name : String
    #
    #   def {{method_prefix}}name : String
    #     {{var_prefix}}name
    #   end
    # end
    # ```
    #
    # The type declaration can also include an initial value:
    #
    # ```
    # class Person
    #   {{macro_prefix}}getter name : String = "John Doe"
    # end
    # ```
    #
    # Is the same as writing:
    #
    # ```
    # class Person
    #   {{var_prefix}}name : String = "John Doe"
    #
    #   def {{method_prefix}}name : String
    #     {{var_prefix}}name
    #   end
    # end
    # ```
    #
    # An assignment can be passed too, but in this case the type of the
    # variable must be easily inferrable from the initial value:
    #
    # ```
    # class Person
    #   {{macro_prefix}}getter name = "John Doe"
    # end
    # ```
    #
    # Is the same as writing:
    #
    # ```
    # class Person
    #   {{var_prefix}}name = "John Doe"
    #
    #   def {{method_prefix}}name : String
    #     {{var_prefix}}name
    #   end
    # end
    # ```
    #
    # If a block is given to the macro, a getter is generated
    # with a variable that is lazily initialized with
    # the block's contents:
    #
    # ```
    # class Person
    #   {{macro_prefix}}getter(birth_date) { Time.local }
    # end
    # ```
    #
    # Is the same as writing:
    #
    # ```
    # class Person
    #   def {{method_prefix}}birth_date
    #     if (value = {{var_prefix}}birth_date).nil?
    #       {{var_prefix}}birth_date = Time.local
    #     else
    #       value
    #     end
    #   end
    # end
    # ```
    macro {{macro_prefix}}getter(*names, &block)
      \{% if block %}
        \{% if names.size != 1 %}
          \{{ raise "Only one argument can be passed to `getter` with a block" }}
        \{% end %}

        \{% name = names[0] %}

        \{% if name.is_a?(TypeDeclaration) %}
          {{var_prefix}}\{{name.var.id}} : \{{name.type}}?

          def {{method_prefix}}\{{name.var.id}}
            if (value = {{var_prefix}}\{{name.var.id}}).nil?
              {{var_prefix}}\{{name.var.id}} = \{{yield}}
            else
              value
            end
          end
        \{% else %}
          def {{method_prefix}}\{{name.id}}
            if (value = {{var_prefix}}\{{name.id}}).nil?
              {{var_prefix}}\{{name.id}} = \{{yield}}
            else
              value
            end
          end
        \{% end %}
      \{% else %}
        \{% for name in names %}
          \{% if name.is_a?(TypeDeclaration) %}
            {{var_prefix}}\{{name}}

            def {{method_prefix}}\{{name.var.id}} : \{{name.type}}
              {{var_prefix}}\{{name.var.id}}
            end
          \{% elsif name.is_a?(Assign) %}
            {{var_prefix}}\{{name}}

            def {{method_prefix}}\{{name.target.id}}
              {{var_prefix}}\{{name.target.id}}
            end
          \{% else %}
            def {{method_prefix}}\{{name.id}}
              {{var_prefix}}\{{name.id}}
            end
          \{% end %}
        \{% end %}
      \{% end %}
    end

    # Defines raise-on-nil and nilable getter methods for each of the given arguments.
    #
    # Writing:
    #
    # ```
    # class Person
    #   {{macro_prefix}}getter! name
    # end
    # ```
    #
    # Is the same as writing:
    #
    # ```
    # class Person
    #   def {{method_prefix}}name?
    #     {{var_prefix}}name
    #   end
    #
    #   def {{method_prefix}}name
    #     {{var_prefix}}name.not_nil!
    #   end
    # end
    # ```
    #
    # The arguments can be string literals, symbol literals or plain names:
    #
    # ```
    # class Person
    #   {{macro_prefix}}getter! :name, "age"
    # end
    # ```
    #
    # If a type declaration is given, a variable with that name
    # is declared with that type, as nilable.
    #
    # ```
    # class Person
    #   {{macro_prefix}}getter! name : String
    # end
    # ```
    #
    # is the same as writing:
    #
    # ```
    # class Person
    #   {{var_prefix}}name : String?
    #
    #   def {{method_prefix}}name?
    #     {{var_prefix}}name
    #   end
    #
    #   def {{method_prefix}}name
    #     {{var_prefix}}name.not_nil!
    #   end
    # end
    # ```
    macro {{macro_prefix}}getter!(*names)
      \{% for name in names %}
        \{% if name.is_a?(TypeDeclaration) %}
          {{var_prefix}}\{{name}}?
          \{% name = name.var %}
        \{% end %}

        def {{method_prefix}}\{{name.id}}?
          {{var_prefix}}\{{name.id}}
        end

        def {{method_prefix}}\{{name.id}}
          {{var_prefix}}\{{name.id}}.not_nil!
        end
      \{% end %}
    end

    # Defines query getter methods for each of the given arguments.
    #
    # Writing:
    #
    # ```
    # class Person
    #   {{macro_prefix}}getter? happy
    # end
    # ```
    #
    # Is the same as writing:
    #
    # ```
    # class Person
    #   def {{method_prefix}}happy?
    #     {{var_prefix}}happy
    #   end
    # end
    # ```
    #
    # The arguments can be string literals, symbol literals or plain names:
    #
    # ```
    # class Person
    #   {{macro_prefix}}getter? :happy, "famous"
    # end
    # ```
    #
    # If a type declaration is given, a variable with that name
    # is declared with that type.
    #
    # ```
    # class Person
    #   {{macro_prefix}}getter? happy : Bool
    # end
    # ```
    #
    # is the same as writing:
    #
    # ```
    # class Person
    #   {{var_prefix}}happy : Bool
    #
    #   def {{method_prefix}}happy? : Bool
    #     {{var_prefix}}happy
    #   end
    # end
    # ```
    #
    # The type declaration can also include an initial value:
    #
    # ```
    # class Person
    #   {{macro_prefix}}getter? happy : Bool = true
    # end
    # ```
    #
    # Is the same as writing:
    #
    # ```
    # class Person
    #   {{var_prefix}}happy : Bool = true
    #
    #   def {{method_prefix}}happy? : Bool
    #     {{var_prefix}}happy
    #   end
    # end
    # ```
    #
    # An assignment can be passed too, but in this case the type of the
    # variable must be easily inferrable from the initial value:
    #
    # ```
    # class Person
    #   {{macro_prefix}}getter? happy = true
    # end
    # ```
    #
    # Is the same as writing:
    #
    # ```
    # class Person
    #   {{var_prefix}}happy = true
    #
    #   def {{method_prefix}}happy?
    #     {{var_prefix}}happy
    #   end
    # end
    # ```
    #
    # If a block is given to the macro, a getter is generated
    # with a variable that is lazily initialized with
    # the block's contents, for examples see `#{{macro_prefix}}getter`.
    macro {{macro_prefix}}getter?(*names, &block)
      \{% if block %}
        \{% if names.size != 1 %}
          \{{ raise "Only one argument can be passed to `getter?` with a block" }}
        \{% end %}

        \{% name = names[0] %}

        \{% if name.is_a?(TypeDeclaration) %}
          {{var_prefix}}\{{name.var.id}} : \{{name.type}}?

          def {{method_prefix}}\{{name.var.id}}?
            if (value = {{var_prefix}}\{{name.var.id}}).nil?
              {{var_prefix}}\{{name.var.id}} = \{{yield}}
            else
              value
            end
          end
        \{% else %}
          def {{method_prefix}}\{{name.id}}?
            if (value = {{var_prefix}}\{{name.id}}).nil?
              {{var_prefix}}\{{name.id}} = \{{yield}}
            else
              value
            end
          end
        \{% end %}
      \{% else %}
        \{% for name in names %}
          \{% if name.is_a?(TypeDeclaration) %}
            {{var_prefix}}\{{name}}

            def {{method_prefix}}\{{name.var.id}}? : \{{name.type}}
              {{var_prefix}}\{{name.var.id}}
            end
          \{% elsif name.is_a?(Assign) %}
            {{var_prefix}}\{{name}}

            def {{method_prefix}}\{{name.target.id}}?
              {{var_prefix}}\{{name.target.id}}
            end
          \{% else %}
            def {{method_prefix}}\{{name.id}}?
              {{var_prefix}}\{{name.id}}
            end
          \{% end %}
        \{% end %}
      \{% end %}
    end

    # Defines setter methods for each of the given arguments.
    #
    # Writing:
    #
    # ```
    # class Person
    #   {{macro_prefix}}setter name
    # end
    # ```
    #
    # Is the same as writing:
    #
    # ```
    # class Person
    #   def {{method_prefix}}name=({{var_prefix}}name)
    #   end
    # end
    # ```
    #
    # The arguments can be string literals, symbol literals or plain names:
    #
    # ```
    # class Person
    #   {{macro_prefix}}setter :name, "age"
    # end
    # ```
    #
    # If a type declaration is given, a variable with that name
    # is declared with that type.
    #
    # ```
    # class Person
    #   {{macro_prefix}}setter name : String
    # end
    # ```
    #
    # is the same as writing:
    #
    # ```
    # class Person
    #   {{var_prefix}}name : String
    #
    #   def {{method_prefix}}name=({{var_prefix}}name : String)
    #   end
    # end
    # ```
    #
    # The type declaration can also include an initial value:
    #
    # ```
    # class Person
    #   {{macro_prefix}}setter name : String = "John Doe"
    # end
    # ```
    #
    # Is the same as writing:
    #
    # ```
    # class Person
    #   {{var_prefix}}name : String = "John Doe"
    #
    #   def {{method_prefix}}name=({{var_prefix}}name : String)
    #   end
    # end
    # ```
    #
    # An assignment can be passed too, but in this case the type of the
    # variable must be easily inferrable from the initial value:
    #
    # ```
    # class Person
    #   {{macro_prefix}}setter name = "John Doe"
    # end
    # ```
    #
    # Is the same as writing:
    #
    # ```
    # class Person
    #   {{var_prefix}}name = "John Doe"
    #
    #   def {{method_prefix}}name=({{var_prefix}}name)
    #   end
    # end
    # ```
    macro {{macro_prefix}}setter(*names)
      \{% for name in names %}
        \{% if name.is_a?(TypeDeclaration) %}
          {{var_prefix}}\{{name}}

          def {{method_prefix}}\{{name.var.id}}=({{var_prefix}}\{{name.var.id}} : \{{name.type}})
          end
        \{% elsif name.is_a?(Assign) %}
          {{var_prefix}}\{{name}}

          def {{method_prefix}}\{{name.target.id}}=({{var_prefix}}\{{name.target.id}})
          end
        \{% else %}
          def {{method_prefix}}\{{name.id}}=({{var_prefix}}\{{name.id}})
          end
        \{% end %}
      \{% end %}
    end

    # Defines property methods for each of the given arguments.
    #
    # Writing:
    #
    # ```
    # class Person
    #   {{macro_prefix}}property name
    # end
    # ```
    #
    # Is the same as writing:
    #
    # ```
    # class Person
    #   def {{method_prefix}}name=({{var_prefix}}name)
    #   end
    #
    #   def {{method_prefix}}name
    #     {{var_prefix}}name
    #   end
    # end
    # ```
    #
    # The arguments can be string literals, symbol literals or plain names:
    #
    # ```
    # class Person
    #   {{macro_prefix}}property :name, "age"
    # end
    # ```
    #
    # If a type declaration is given, a variable with that name
    # is declared with that type.
    #
    # ```
    # class Person
    #   {{macro_prefix}}property name : String
    # end
    # ```
    #
    # Is the same as writing:
    #
    # ```
    # class Person
    #   {{var_prefix}}name : String
    #
    #   def {{method_prefix}}name=({{var_prefix}}name)
    #   end
    #
    #   def {{method_prefix}}name
    #     {{var_prefix}}name
    #   end
    # end
    # ```
    #
    # The type declaration can also include an initial value:
    #
    # ```
    # class Person
    #   {{macro_prefix}}property name : String = "John Doe"
    # end
    # ```
    #
    # Is the same as writing:
    #
    # ```
    # class Person
    #   {{var_prefix}}name : String = "John Doe"
    #
    #   def {{method_prefix}}name=({{var_prefix}}name : String)
    #   end
    #
    #   def {{method_prefix}}name
    #     {{var_prefix}}name
    #   end
    # end
    # ```
    #
    # An assignment can be passed too, but in this case the type of the
    # variable must be easily inferrable from the initial value:
    #
    # ```
    # class Person
    #   {{macro_prefix}}property name = "John Doe"
    # end
    # ```
    #
    # Is the same as writing:
    #
    # ```
    # class Person
    #   {{var_prefix}}name = "John Doe"
    #
    #   def {{method_prefix}}name=({{var_prefix}}name : String)
    #   end
    #
    #   def {{method_prefix}}name
    #     {{var_prefix}}name
    #   end
    # end
    # ```
    #
    # If a block is given to the macro, a property is generated
    # with a variable that is lazily initialized with
    # the block's contents:
    #
    # ```
    # class Person
    #   {{macro_prefix}}property(birth_date) { Time.local }
    # end
    # ```
    #
    # Is the same as writing:
    #
    # ```
    # class Person
    #   def {{method_prefix}}birth_date
    #     if (value = {{var_prefix}}birth_date).nil?
    #       {{var_prefix}}birth_date = Time.local
    #     else
    #       value
    #     end
    #   end
    #
    #   def {{method_prefix}}birth_date=({{var_prefix}}birth_date)
    #   end
    # end
    # ```
    macro {{macro_prefix}}property(*names, &block)
      \{% if block %}
        \{% if names.size != 1 %}
          \{{ raise "Only one argument can be passed to `property` with a block" }}
        \{% end %}

        \{% name = names[0] %}

        {{macro_prefix}}setter \{{name}}

        \{% if name.is_a?(TypeDeclaration) %}
          {{var_prefix}}\{{name.var.id}} : \{{name.type}}?

          def {{method_prefix}}\{{name.var.id}}
            if (value = {{var_prefix}}\{{name.var.id}}).nil?
              {{var_prefix}}\{{name.var.id}} = \{{yield}}
            else
              value
            end
          end
        \{% else %}
          def {{method_prefix}}\{{name.id}}
            if (value = {{var_prefix}}\{{name.id}}).nil?
              {{var_prefix}}\{{name.id}} = \{{yield}}
            else
              value
            end
          end
        \{% end %}
      \{% else %}
        \{% for name in names %}
          \{% if name.is_a?(TypeDeclaration) %}
            {{var_prefix}}\{{name}}

            def {{method_prefix}}\{{name.var.id}} : \{{name.type}}
              {{var_prefix}}\{{name.var.id}}
            end

            def {{method_prefix}}\{{name.var.id}}=({{var_prefix}}\{{name.var.id}} : \{{name.type}})
            end
          \{% elsif name.is_a?(Assign) %}
            {{var_prefix}}\{{name}}

            def {{method_prefix}}\{{name.target.id}}
              {{var_prefix}}\{{name.target.id}}
            end

            def {{method_prefix}}\{{name.target.id}}=({{var_prefix}}\{{name.target.id}})
            end
          \{% else %}
            def {{method_prefix}}\{{name.id}}
              {{var_prefix}}\{{name.id}}
            end

            def {{method_prefix}}\{{name.id}}=({{var_prefix}}\{{name.id}})
            end
          \{% end %}
        \{% end %}
      \{% end %}
    end

    # Defines raise-on-nil property methods for each of the given arguments.
    #
    # Writing:
    #
    # ```
    # class Person
    #   {{macro_prefix}}property! name
    # end
    # ```
    #
    # Is the same as writing:
    #
    # ```
    # class Person
    #   def {{method_prefix}}name=({{var_prefix}}name)
    #   end
    #
    #   def {{method_prefix}}name?
    #     {{var_prefix}}name
    #   end
    #
    #   def {{method_prefix}}name
    #     {{var_prefix}}name.not_nil!
    #   end
    # end
    # ```
    #
    # The arguments can be string literals, symbol literals or plain names:
    #
    # ```
    # class Person
    #   {{macro_prefix}}property! :name, "age"
    # end
    # ```
    #
    # If a type declaration is given, a variable with that name
    # is declared with that type, as nilable.
    #
    # ```
    # class Person
    #   {{macro_prefix}}property! name : String
    # end
    # ```
    #
    # Is the same as writing:
    #
    # ```
    # class Person
    #   {{var_prefix}}name : String?
    #
    #   def {{method_prefix}}name=({{var_prefix}}name)
    #   end
    #
    #   def {{method_prefix}}name?
    #     {{var_prefix}}name
    #   end
    #
    #   def {{method_prefix}}name
    #     {{var_prefix}}name.not_nil!
    #   end
    # end
    # ```
    macro {{macro_prefix}}property!(*names)
      {{macro_prefix}}getter! \{{*names}}

      \{% for name in names %}
        \{% if name.is_a?(TypeDeclaration) %}
          def {{method_prefix}}\{{name.var.id}}=({{var_prefix}}\{{name.var.id}} : \{{name.type}})
          end
        \{% else %}
          def {{method_prefix}}\{{name.id}}=({{var_prefix}}\{{name.id}})
          end
        \{% end %}
      \{% end %}
    end

    # Defines query property methods for each of the given arguments.
    #
    # Writing:
    #
    # ```
    # class Person
    #   {{macro_prefix}}property? happy
    # end
    # ```
    #
    # Is the same as writing:
    #
    # ```
    # class Person
    #   def {{method_prefix}}happy=({{var_prefix}}happy)
    #   end
    #
    #   def {{method_prefix}}happy?
    #     {{var_prefix}}happy
    #   end
    # end
    # ```
    #
    # The arguments can be string literals, symbol literals or plain names:
    #
    # ```
    # class Person
    #   {{macro_prefix}}property? :happy, "famous"
    # end
    # ```
    #
    # If a type declaration is given, a variable with that name
    # is declared with that type.
    #
    # ```
    # class Person
    #   {{macro_prefix}}property? happy : Bool
    # end
    # ```
    #
    # Is the same as writing:
    #
    # ```
    # class Person
    #   {{var_prefix}}happy : Bool
    #
    #   def {{method_prefix}}happy=({{var_prefix}}happy : Bool)
    #   end
    #
    #   def {{method_prefix}}happy? : Bool
    #     {{var_prefix}}happy
    #   end
    # end
    # ```
    #
    # The type declaration can also include an initial value:
    #
    # ```
    # class Person
    #   {{macro_prefix}}property? happy : Bool = true
    # end
    # ```
    #
    # Is the same as writing:
    #
    # ```
    # class Person
    #   {{var_prefix}}happy : Bool = true
    #
    #   def {{method_prefix}}happy=({{var_prefix}}happy : Bool)
    #   end
    #
    #   def {{method_prefix}}happy? : Bool
    #     {{var_prefix}}happy
    #   end
    # end
    # ```
    #
    # An assignment can be passed too, but in this case the type of the
    # variable must be easily inferrable from the initial value:
    #
    # ```
    # class Person
    #   {{macro_prefix}}property? happy = true
    # end
    # ```
    #
    # Is the same as writing:
    #
    # ```
    # class Person
    #   {{var_prefix}}happy = true
    #
    #   def {{method_prefix}}happy=({{var_prefix}}happy)
    #   end
    #
    #   def {{method_prefix}}happy?
    #     {{var_prefix}}happy
    #   end
    # end
    # ```
    #
    # If a block is given to the macro, a property is generated
    # with a variable that is lazily initialized with
    # the block's contents, for examples see `#{{macro_prefix}}property`.
    macro {{macro_prefix}}property?(*names, &block)
      \{% if block %}
        \{% if names.size != 1 %}
          \{{ raise "Only one argument can be passed to `property?` with a block" }}
        \{% end %}

        \{% name = names[0] %}

        \{% if name.is_a?(TypeDeclaration) %}
          {{var_prefix}}\{{name.var.id}} : \{{name.type}}?

          def {{method_prefix}}\{{name.var.id}}?
            if (value = {{var_prefix}}\{{name.var.id}}).nil?
              {{var_prefix}}\{{name.var.id}} = \{{yield}}
            else
              value
            end
          end

          def {{method_prefix}}\{{name.var.id}}=({{var_prefix}}\{{name.var.id}} : \{{name.type}})
          end
        \{% else %}
          def {{method_prefix}}\{{name.id}}?
            if (value = {{var_prefix}}\{{name.id}}).nil?
              {{var_prefix}}\{{name.id}} = \{{yield}}
            else
              value
            end
          end

          def {{method_prefix}}\{{name.id}}=({{var_prefix}}\{{name.id}})
          end
        \{% end %}
      \{% else %}
        \{% for name in names %}
          \{% if name.is_a?(TypeDeclaration) %}
            {{var_prefix}}\{{name}}

            def {{method_prefix}}\{{name.var.id}}? : \{{name.type}}
              {{var_prefix}}\{{name.var.id}}
            end

            def {{method_prefix}}\{{name.var.id}}=({{var_prefix}}\{{name.var.id}} : \{{name.type}})
            end
          \{% elsif name.is_a?(Assign) %}
            {{var_prefix}}\{{name}}

            def {{method_prefix}}\{{name.target.id}}?
              {{var_prefix}}\{{name.target.id}}
            end

            def {{method_prefix}}\{{name.target.id}}=({{var_prefix}}\{{name.target.id}})
            end
          \{% else %}
            def {{method_prefix}}\{{name.id}}?
              {{var_prefix}}\{{name.id}}
            end

            def {{method_prefix}}\{{name.id}}=({{var_prefix}}\{{name.id}})
            end
          \{% end %}
        \{% end %}
      \{% end %}
    end
  {% end %}

  # Delegate *methods* to *to*.
  #
  # Note that due to current language limitations this is only useful
  # when no captured blocks are involved.
  #
  # ```
  # class StringWrapper
  #   def initialize(@string : String)
  #   end
  #
  #   delegate downcase, to: @string
  #   delegate gsub, to: @string
  #   delegate empty?, capitalize, to: @string
  #   delegate :[], to: @string
  # end
  #
  # wrapper = StringWrapper.new "HELLO"
  # wrapper.downcase       # => "hello"
  # wrapper.gsub(/E/, "A") # => "HALLO"
  # wrapper.empty?         # => false
  # wrapper.capitalize     # => "Hello"
  # ```
  macro delegate(*methods, to object)
    {% for method in methods %}
      {% if method.id.ends_with?('=') && method.id != "[]=" %}
        def {{method.id}}(arg)
          {{object.id}}.{{method.id}} arg
        end
      {% else %}
        def {{method.id}}(*args, **options)
          {{object.id}}.{{method.id}}(*args, **options)
        end

        {% if method.id != "[]=" %}
          def {{method.id}}(*args, **options)
            {{object.id}}.{{method.id}}(*args, **options) do |*yield_args|
              yield *yield_args
            end
          end
        {% end %}
      {% end %}
    {% end %}
  end

  # Defines a `hash(hasher)` that will append a hash value for the given fields.
  #
  # ```
  # class Person
  #   def initialize(@name, @age)
  #   end
  #
  #   # Define a hash(hasher) method based on @name and @age
  #   def_hash @name, @age
  # end
  # ```
  macro def_hash(*fields)
    def hash(hasher)
      {% for field in fields %}
        hasher = {{field.id}}.hash(hasher)
      {% end %}
      hasher
    end
  end

  # Defines an `==` method by comparing the given fields.
  #
  # The generated `==` method has a `self` restriction.
  #
  # ```
  # class Person
  #   def initialize(@name, @age)
  #   end
  #
  #   # Define a `==` method that compares @name and @age
  #   def_equals @name, @age
  # end
  # ```
  macro def_equals(*fields)
    def ==(other : self)
      {% for field in fields %}
        return false unless {{field.id}} == other.{{field.id}}
      {% end %}
      true
    end
  end

  # Defines `hash` and `==` method from the given fields.
  #
  # The generated `==` method has a `self` restriction.
  #
  # ```
  # class Person
  #   def initialize(@name, @age)
  #   end
  #
  #   # Define a hash method based on @name and @age
  #   # Define a `==` method that compares @name and @age
  #   def_equals_and_hash @name, @age
  # end
  # ```
  macro def_equals_and_hash(*fields)
    def_equals {{*fields}}
    def_hash {{*fields}}
  end
end

struct Float
  # See `Object#hash(hasher)`
  def hash(hasher)
    hasher.float(self)
  end
end

struct Float
  # See `Object#hash(hasher)`
  def hash(hasher)
    hasher.float(self)
  end
end

struct Bool
  # See `Object#hash(hasher)`
  def hash(hasher)
    hasher.bool(self)
  end
end

struct Char
  # See `Object#hash(hasher)`
  def hash(hasher)
    hasher.char(self)
  end
end

struct Symbol
  # See `Object#hash(hasher)`
  def hash(hasher)
    hasher.symbol(self)
  end
end

struct Tuple(T)
  # See `Object#hash(hasher)`
  def hash(hasher)
    {% for i in 0...T.size %}
      hasher = self[{{i}}].hash(hasher)
    {% end %}
    hasher
  end
end

struct NamedTuple
  # Returns a hash value based on this name tuple's size, keys and values.
  #
  # See also: `Object#hash`.
  # See `Object#hash(hasher)`
  def hash(hasher)
    {% for key in T.keys.sort %}
      hasher = {{key.symbolize}}.hash(hasher)
      hasher = self[{{key.symbolize}}].hash(hasher)
    {% end %}
    hasher
  end
end

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

struct Int8
  MIN = -128_i8
  MAX =  127_i8

  def self.new(value)
    value.to_i8
  end
end

struct Int16
  MIN = -32768_i16
  MAX =  32767_i16

  def self.new(value)
    value.to_i16
  end
end

struct Int32
  MIN = -2147483648_i32
  MAX =  2147483647_i32

  def self.new(value)
    value.to_i32
  end
end

struct Int64
  MIN = -9223372036854775808_i64
  MAX =  9223372036854775807_i64

  def self.new(value)
    value.to_i64
  end
end

struct UInt8
  MIN =   0_u8
  MAX = 255_u8

  def abs
    self
  end

  def self.new(value)
    value.to_u8
  end
end

struct UInt16
  MIN =     0_u16
  MAX = 65535_u16

  def abs
    self
  end

  def self.new(value)
    value.to_u16
  end
end

struct UInt32
  MIN =          0_u32
  MAX = 4294967295_u32

  def abs
    self
  end

  def self.new(value)
    value.to_u32
  end
end

struct UInt64
  MIN =                    0_u64
  MAX = 18446744073709551615_u64

  def abs
    self
  end

  def self.new(value)
    value.to_u64
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

  # Returns the address of this pointer.
  #
  # ```
  # ptr = Pointer(Int32).new(1234)
  # ptr.hash # => 1234
  # ```
  def_hash address

  # Returns a pointer whose memory address is zero. This doesn't allocate memory.
  #
  # When calling a C function you can also pass `nil` instead of constructing a
  # null pointer with this method.
  #
  # ```
  # ptr = Pointer(Int32).null
  # ptr.address # => 0
  # ```
  def self.null
    new 0_u64
  end
end

struct Int
  private DIGITS_DOWNCASE = "0123456789abcdefghijklmnopqrstuvwxyz"
  private DIGITS_UPCASE   = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
  private DIGITS_BASE62   = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"

  def times(&block : self ->) : Nil
    i = self ^ self
    while i < self
      yield i
      i += 1
    end
  end

  def self.zero : self
    new(0)
  end

  def abs
    self >= 0 ? self : 0 - self
  end

  def >>(count : Int)
    if count < 0
      self << count.abs
    elsif count < sizeof(self) * 8
      self.unsafe_shr(count)
    else
      self.class.zero
    end
  end

  def <<(count : Int)
    if count < 0
      self >> count.abs
    elsif count < sizeof(self) * 8
      self.unsafe_shl(count)
    else
      self.class.zero
    end
  end

  # Returns this number's *bit*th bit, starting with the least-significant.
  #
  # ```
  # 11.bit(0) # => 1
  # 11.bit(1) # => 1
  # 11.bit(2) # => 0
  # 11.bit(3) # => 1
  # 11.bit(4) # => 0
  # ```
  def bit(bit)
    self >> bit & 1
  end

  # Returns `true` if all bits in *mask* are set on `self`.
  #
  # ```
  # 0b0110.bits_set?(0b0110) # => true
  # 0b1101.bits_set?(0b0111) # => false
  # 0b1101.bits_set?(0b1100) # => true
  # ```
  def bits_set?(mask)
    (self & mask) == mask
  end

  # Returns `self` modulo *other*.
  #
  # This uses floored division.
  #
  # See `Int#/` for more details.
  def %(other : Int)
    if other == 0
      abort()
    elsif (self ^ other) >= 0
      self.unsafe_mod(other)
    else
      me = self.unsafe_mod(other)
      me == 0 ? me : me + other
    end
  end

  def remainder(other : Int)
    if other == 0
      abort()
    else
      unsafe_mod other
    end
  end

  private def check_div_argument(other)
    if other == 0
      abort()
    end

    {% begin %}
          if self < 0 && self == {{@type}}::MIN && other == -1
            Logger.error "Overflow"
            abort()
          end
        {% end %}
  end

  def tdiv(other : Int)
    check_div_argument other

    unsafe_div other
  end

  def /(other : Int)
    check_div_argument other

    div = unsafe_div other
    mod = unsafe_mod other
    div -= 1 if other > 0 ? mod < 0 : mod > 0
    div
  end

  # See `Object#hash(hasher)`
  def hash(hasher)
    hasher.int(self)
  end

  def internal_to_s(base, upcase = false)
    # Given sizeof(self) <= 128 bits, we need at most 128 bytes for a base 2
    # representation, plus one byte for the trailing 0.
    chars = uninitialized UInt8[129]
    ptr_end = chars.to_unsafe + 128
    ptr = ptr_end
    num = self

    neg = num < 0

    digits = (base == 62 ? DIGITS_BASE62 : (upcase ? DIGITS_UPCASE : DIGITS_DOWNCASE)).to_unsafe

    while num != 0
      ptr += -1
      ptr.value = digits[num.remainder(base).abs]
      num = num.tdiv(base)
    end

    if neg
      ptr += -1
      ptr.value = '-'.ord.to_u8
    end

    count = (ptr_end - ptr).to_i32
    yield ptr, count
  end

  def ~
    self ^ -1
  end
end

struct StaticArray(T, N)
  private def check_index_out_of_bounds(index)
    check_index_out_of_bounds(index) {
      abort()
    }
  end

  private def check_index_out_of_bounds(index)
    index += size if index < 0
    if 0 <= index < size
      index
    else
      yield
    end
  end

  @[AlwaysInline]
  def [](index : Int)
    index = check_index_out_of_bounds index
    to_unsafe[index]
  end

  @[AlwaysInline]
  def []=(index : Int, value : T)
    index = check_index_out_of_bounds index
    to_unsafe[index] = value
  end

  def update(index : Int)
    index = check_index_out_of_bounds index
    to_unsafe[index] = yield to_unsafe[index]
  end

  def size
    N
  end

  def []=(value : T)
    size.times do |i|
      to_unsafe[i] = value
    end
  end

  def to_unsafe : Pointer(T)
    pointerof(@buffer)
  end

  # See `Object#hash(hasher)`
  def hash(hasher)
    hasher = size.hash(hasher)
    each do |elem|
      hasher = elem.hash(hasher)
    end
    hasher
  end
end

class Class
  # See `Object#hash(hasher)`
  def hash(hasher)
    hasher.class(self)
  end
end

class Reference
  # Returns `true` if this reference is the same as *other*. Invokes `same?`.
  def ==(other : self)
    same?(other)
  end

  # Returns `false` (other can only be a `Value` here).
  def ==(other)
    false
  end

  # Returns `true` if this reference is the same as *other*. This is only
  # `true` if this reference's `object_id` is the same as *other*'s.
  def same?(other : Reference)
    object_id == other.object_id
  end

  # Returns `false`: a reference is never `nil`.
  def same?(other : Nil)
    false
  end

  # See `Object#hash(hasher)`
  def hash(hasher)
    hasher.reference(self)
  end
end

class Exception
  getter message : String?
  getter cause : Exception?

  def initialize(@message : String? = nil, @cause : Exception? = nil)
  end
end

class ArgumentError < Exception
  def initialize(message = "Argument error")
    super(message)
  end
end

def raise(exception : Exception) : NoReturn
  panic("Exception raised")
end
