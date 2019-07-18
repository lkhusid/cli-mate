abstract class BatchSolver
  property target = DEFAULT_TARGET
  property card_size = 4
  property card_count = 0

  protected property execution_time = 0.0
  protected property solved_count = 0
  protected property solved_with_fraction_count = 0
  protected property no_solution_count = 0

  protected property solved_with_fraction_cards = [] of Card

  def initialize(@card_size, @target)
  end

  protected def add_solvable(card)
    @solved_count += 1
    output_progress
  end

  protected def add_solvable_with_fractions(card)
    @solved_with_fraction_count += 1
    @solved_with_fraction_cards << card
    output_progress
  end

  protected def add_no_solution(card)
    @no_solution_count += 1
    output_progress
  end

  protected def output_progress
    if (solved_count + solved_with_fraction_count + no_solution_count) % 1000 == 0
      print "Solving: #{solved_count + solved_with_fraction_count + no_solution_count} of #{card_count}\r"
    end
  end

  protected def output_final_results
    width = @card_count.to_s.size
    puts " " * 50
    puts "Total:                    #{@card_count}"
    puts "Solveable:                #{@solved_count.to_s.rjust(width)} (#{(100.0 * @solved_count / @card_count).round(1).to_s.rjust(4)}%)"
    puts "Solveable with fractions: #{@solved_with_fraction_count.to_s.rjust(width)} (#{(100.0 * @solved_with_fraction_count / @card_count).round(1).to_s.rjust(4)}%)"
    puts "Not solveable:            #{@no_solution_count.to_s.rjust(width)} (#{(100.0 * @no_solution_count / @card_count).round(1).to_s.rjust(4)}%)"
    puts "\nDone in #{@execution_time.round(2)} sec"
    # if solved_with_fraction_cards.size > 0
    # puts("====================================")
    # @solved_with_fraction_cards.each { |c| puts c.to_s }
    # end
  end

  abstract def solve
end

class SingleThreadBatchSolver < BatchSolver
  def solve
    t = Time.now
    e = CardEnumeration.new(@card_size, DEFAULT_TARGET)
    while (card = e.next_card)
      @card_count += 1

      if card.solve(false)
        add_solvable(card)
      elsif card.solve(true)
        add_solvable_with_fractions(card)
      else
        add_no_solution(card)
      end
    end
    @execution_time = (Time.now - t).total_seconds
    output_final_results
  end
end
