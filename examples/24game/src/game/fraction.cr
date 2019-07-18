struct Fraction
  ONE = Fraction.new(1, 1)
  OPS = {
    "+" => ->(x : Fraction, y : Fraction) { x + y },
    "-" => ->(x : Fraction, y : Fraction) { x - y },
    "*" => ->(x : Fraction, y : Fraction) { x * y },
    "/" => ->(x : Fraction, y : Fraction) { x / y },
  }

  property numerator = 0
  property denominator = 1

  def initialize(@numerator)
  end

  def initialize(@numerator, @denominator)
  end

  private def gcd(x, y)
    return 1 if x == 0 || y == 0

    if x < y
      r = x
      x = y
      y = r
    end

    r = x % y
    while r != 0
      x = y
      y = r
      r = x % y
    end
    y
  end

  private def reduce(n, d)
    if d < 0
      n = -n
      d = -d
    end
    g = gcd(n, d)
    Fraction.new(n / g, d / g)
  end

  def +(b)
    return add(b.numerator, b.denominator)
  end

  def add(n, d)
    return reduce(@numerator * d + n * @denominator, @denominator * d)
  end

  def -(b)
    add(-b.numerator, b.denominator)
  end

  def *(b)
    return multiply(b.numerator, b.denominator)
  end

  def multiply(n, d)
    reduce(@numerator * n, @denominator * d)
  end

  def /(b)
    multiply(b.denominator, b.numerator)
  end

  def ==(b)
    return @numerator == b.numerator && @denominator == b.denominator
  end

  def to_s(io : IO)
    io << (@denominator == 1 ? @numerator.to_s : "#{@numerator}/#{@denominator}")
  end

  def int?
    @denominator == 1
  end
end
