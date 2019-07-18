require "cli-mate"
require "./game/game"

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


class TwentyFourCli < CliMate::Runner
  name "24"
  header "Card solver for game '24'. Solves a specific card (one at a time) or a whole batch to find all solvable cards of a given size."
  footer "See wikipedia this wikipedia link for rules and details: https://en.wikipedia.org/wiki/24_Game"
  default "solve"

  options({target: 24}) do |parser|
    parser.separator("  Target:")
    parser.on("-t", "--target TARGET", "Target to solve for, defaults to 24.") { |t| options.target = t.to_i }
  end

end

class SolveCmd < CliMate::Command
  name  "solve"
  usage "solve card|batch ..."
  desc  "Solves a card or a whole batchhel"
  default "card"

  class CardCmd < CliMate::Command
    name  "card"
    usage "solve card NUMBER NUMBER...\nExample:\n  solve card 4 6 7 8"
    desc  "Solves one card of various length"

    options({fractions: false}) do |parser|
      parser.on("-f", "--with-fractions", "Allow solution with fractions.") {options.fractions = true}
    end

    def run(opts, args)
      t = Time.now
      card = Card.new(opts.target, args)
      card.solve(false) || (opts.fractions && card.solve(true))
      t = Time.now - t
      say card.solution ? card.to_s.green : card.to_s.red
      say "Done in #{t.total_seconds}ms"
    end
  end

  class BatchCmd < CliMate::Command
    name  "batch"
    usage "solve batch [CARD_LENGTH]\nExample:\n  batch 3"
    desc  "Solves all possible cards of a given length or 4 number cards if length is not specified."

    def run(opts, args)
      SingleThreadBatchSolver.new(args[0].to_i, opts.target).solve()
    end
  end
end

TwentyFourCli.new.start(ARGV)
