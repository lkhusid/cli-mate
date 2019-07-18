class Card
  property target = DEFAULT_TARGET

  property numbers : Array(Fraction)
  property solution : String?

  def initialize(@target, numbers : Array(String))
    @numbers = numbers.map { |n| Fraction.new(n.to_i) }
  end

  def initialize(@target, *numbers : Int32)
    @numbers = numbers.to_a.map { |n| Fraction.new(n) }
  end

  def initialize(@target, *numbers : Fraction)
    @numbers = numbers.to_a
  end

  def initialize(@target, numbers : Fraction)
    @numbers = numbers
  end

  def initialize(@target, numbers)
    @numbers = numbers
  end

  def to_s
    "#{numbers.map(&.to_s).join(" ")} --> #{solution || "No solution!"}"
  end

  def solve(fractions)
    @solution = solve(fractions, numbers)
  end

  private def solve(fractions, numbers)
    tried_pairs = StaticArray(Int32, 25).new(0)
    new_size = numbers.size - 1
    if new_size > 1
      new_numbers_t = Array(Fraction).new(new_size)
      new_size.times.each {new_numbers_t << Fraction::ONE}
    end
    numbers.each_with_index do |a, i|
      numbers.each_with_index do |b, j|
        next if i == j

        pair = a.numerator * target * target * target + a.denominator * target * target + b.numerator * target + b.denominator
        skip = false
        tried_pairs.each_with_index do |p, i|
          if p == pair
            skip = true
            break
          elsif p == 0
            tried_pairs[i] = pair
            break
          end
        end
        next if skip

        Fraction::OPS.each do |(op_name, op)|
          next if op_name == "/" && b.numerator.to_i == 0
          new_number = op.call(a, b)

          if numbers.size == 2
            if new_number.numerator.to_i == target && new_number.int?
              return "#{a} #{op_name} #{b} = #{target}"
            end
          else
            next if !fractions && !new_number.int?
            new_numbers = new_numbers_t.as(Array(Fraction))
            new_numbers[0] = new_number
            q = 1
            numbers.each_with_index do |n, k|
              unless k == i || k == j
                new_numbers[q] = n
                q += 1
              end
            end
            if s = solve(fractions, new_numbers)
              return "#{a} #{op_name} #{b} = #{new_number} | #{s}"
            end
          end
        end
      end
    end
    return nil
  end
end

class CardEnumeration
  private property target : Int32
  private property numbers = [] of Fraction

  def initialize(size, @target = DEFAULT_TARGET, min_value = 1)
    size.times { |i| numbers << Fraction.new(min_value, 1) }
    @next_card = Card.new(target, numbers)
  end

  def next_card
    return nil unless @next_card

    card = @next_card
    numbers = @next_card.as(Card).numbers
    size = numbers.size
    next_numbers = nil
    size.times do |i|
      if numbers[-i - 1].numerator < target
        next_numbers = numbers.dup
        next_numbers[-i - 1] = next_numbers[-i - 1].add(1, 1)
        i.times { |j| next_numbers[-i + j] = next_numbers[-i - 1] }
        break
      end
    end
    @next_card = next_numbers ? Card.new(target, next_numbers) : nil

    card
  end
end
