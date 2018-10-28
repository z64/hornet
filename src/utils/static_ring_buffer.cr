require "json"

# Optimized implementation of a fixed sized ring buffer that exposes
# a simple and "safe" API of `#push` and `#to_a`. `#push`ing to a full
# buffer erases the oldest member.
#
# ```
# # Create a new buffer of Int32, with size 3
# buffer = StaticRingBuffer(Int32, 3).new
# buffer.push(1)
# buffer.push(2)
# buffer.push(3)
# buffer.push(4)
# buffer.to_a # => [2, 3, 4]
# ```
class StaticRingBuffer(T, N)
  def initialize
    @buffer = Pointer(T?).malloc(N) { nil }
    @write_index = 0
  end

  # Push a new element into the buffer
  def push(elem : T)
    @buffer[@write_index] = elem
    @write_index = (@write_index + 1) % N
  end

  # Yields each element of the buffer
  def each
    N.times do |i|
      index = (@write_index + i) % N
      if value = @buffer[index]
        yield value
      end
    end
  end

  # Returns a copy of the current buffer as an `Array(T)`
  def to_a : Array(T)
    arr = Array(T).new(N)
    each { |e| arr << e }
    arr
  end

  # Serializes this buffer to a `JSON::Builder`
  def to_json(builder : JSON::Builder)
    builder.array do
      each { |e| e.to_json(builder) }
    end
  end
end
