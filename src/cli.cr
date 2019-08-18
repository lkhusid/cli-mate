require "json"
require "option_parser"
require "readline"
require "./helpers"

lib LibReadline
  struct HistoryEntry
    line : UInt8*
    # timestamp : UInt8*
    # data :  Void*
  end

  alias HistEntryArray = HistoryEntry*

  fun write_history(file : UInt8*) : Int32
  fun read_history(file : UInt8*) : Int32
  fun stifle_history(Int32)
  fun history_get(Int32) : HistoryEntry*
  fun history_list : HistEntryArray*
  $history_length : Int32
end

module CliMate
  COMMANDS = [] of Command.class

  module CommonDeclarations
    property commands = [] of Command
    @[JSON::Field(ignore: true)]
    protected property parser : OptionParser = OptionParser.new
    protected property arguments : Array(String) = [] of String

    def parser_options(@parser)
    end

    macro options(model, &block)
      class CliMate::Options
        {% for name, default_value in model %}
          property {{name.id}} = {{default_value}}
        {% end %}
      end

      def parser_options(parser)
        Proc(OptionParser, Void).new {{block.id}}.call(parser)
      end
    end

    def name
      self.class.name.split("::").last.downcase.gsub("command", "").gsub("cmd", "")
    end

    macro name(text)
      def name
        {{text}}
      end
    end

    def default
      ""
    end

    macro default(name)
      def default
        {{name}}
      end
    end

    protected def parse_args(args, exclude_double_dash = false)
      double_dash_index = args.index("--")
      if double_dash_index
        double_dash_index += 1 if exclude_double_dash
        after_double_dash = args[double_dash_index..-1]
      end
      @parser.parse(args)
      @arguments += after_double_dash if after_double_dash
  end

    protected def match_command(args)
      index = -1
      args.map(&.downcase).each_with_index do |a, i|
        cmd = commands.find { |c| c.name == a }
        if cmd
          args.delete_at(i)
          return cmd
        end
      end
      return nil
    end
  end


  class Options
    include JSON::Serializable
    property verbose = 0
    property _sticky = false

    def initialize
    end

    def copy(other)
      {% for name in @type.instance_vars %}
        @{{name}} = other.{{name}}
      {% end %}
    end
  end

  class Runner
    include CliMate::Helpers
    include CommonDeclarations

    private HISTORY_LENGTH = 1000

    getter options = CliMate::Options.new
    property sticky_options = false
    getter history_file_name : String = ""

    def header
    end

    macro header(text)
      def header
        {{text}}
      end
    end

    def footer
    end

    macro footer(text)
      def footer
        {{text}}
      end
    end

    def initialize
      parser_options(@parser)

      @parser.separator("\n  Output:")
      @parser.on("--no-color", "No output coloring or font formatting.") { String.with_color = false }
      @parser.on("--silent", "No output.") { silent(true) }
      @parser.on("--log-info", "INFO level of verbosity.") { @options.verbose = 1 }
      @parser.on("-v", "--log-debug", "Debug level of verbosity, very verbose.") { @options.verbose = 2 }


      @parser.separator("\n  Help:")
      @parser.on("-h", "--help", "Show full help.") do
        show_help
        exit(0)
      end

      @parser.unknown_args { |args| @arguments = args }
      @parser.invalid_option { |msg| }
      @parser.missing_option do |msg|
        say "Missing option value: #{msg}".red
        say "#{"Options:".bold}\n#{@parser}\n\n"
        stop
      end

      cmd_map = COMMANDS.to_h {|c| {c.name, c.new(self).prepare}}
      cmd_map.each do |name, cmd|
        parent_name = name.split("::")[0..-2].join("::")
        parent = parent_name.blank? ? nil : cmd_map[parent_name]?
        if parent
          parent.commands << cmd
        else
          commands << cmd
        end
      end
    end

    def show_help
      say "#{header}\n"
      say "#{"Usage:".bold}\n  #{name} [OPTIONS] [[COMMAND [COMMAND_OPTIONS]]...] [ARGUMENTS]\n\n"
      say "#{"Options:".bold}\n#{@parser}\n\n"
      say "#{"Commands:".bold}\n"
      grouped_cmds = commands.group_by(&.category)
      grouped_cmds.keys.sort.each do |category|
        say "  #{category}:"
        grouped_cmds[category].sort_by(&.name).each do |c|
          say "    #{c.name.ljust(25)}#{c.desc}"
          c.show_subcommands_help("  ... ", 25)
        end
        say
      end
      say "\n#{footer}\n"
    end

    def start(args)
      begin
        parse_args(args)

        if @arguments.size > 0
            execute(options, @arguments)
        else
          # REPL mode.
          @parser.separator("\n  Sticky options:")
          @parser.on("--sticky-options", "Store current options as defaults for future commands.") { @options._sticky = true }

          @history_file_name = File.expand_path("~/.#{name}_history")
          LibReadline.read_history(@history_file_name)
          LibReadline.stifle_history(HISTORY_LENGTH)
          prompt = "#{"==>".invert} "
          while input = Readline.readline(prompt, false)
            next if input.empty?
            input = input.strip
            if input.starts_with?("hist")
              hist_length = LibReadline.history_length
              hist_length.times do |i|
                say "#{i + 1}. #{String.new(LibReadline.history_get(i + 1).value.line)}"
              end
            else
              if input[0] == '!'
                i = input[1..-1].to_i
                input = "#{String.new(LibReadline.history_get(i).value.line)}" if i < LibReadline.history_length
              end
              last_input = LibReadline.history_length == 0 ? "#{input}x" : String.new(LibReadline.history_get(LibReadline.history_length).value.line)
              LibReadline.add_history(input) unless last_input == input
              input.super_split(";").each do |command|
                t = Time.now
                cmd = command.gsub(/^time\s+/i, "")
                orig_options = options.dup
                begin
                  parse_args(cmd.strip.super_split(/\s+/))
                  execute(@options, arguments)
                rescue e : CliMate::Helpers::ExitException
                rescue e : Exception
                  say e.message.as(String).red if e.message
                  say "   #{e.backtrace.join("\n   ")}" if options.verbose > 0
                ensure
                  @options.copy(orig_options) unless @options._sticky
                  @options._sticky = false
                end
                say "Done in #{(Time.now - t).total_seconds.to_s.bold} sec" unless cmd == command
              end
            end
          end
        end
      rescue e : CliMate::Helpers::ExitException
        exit(1)
      end
    end

    def run(opts, args)
      say "Unknown command: #{args.join(" ").red!.bold}".red
    end

    protected def execute(opts, args)
      cmd = match_command(args) || (default.blank? ? nil : match_command(args.unshift(default)))
      if cmd
        cmd.execute(opts, args)
      else
        run(opts, args)
      end
    end
  end

  abstract class Command
    include JSON::Serializable
    include CliMate::Helpers
    include CommonDeclarations

    @[JSON::Field(ignore: true)]
    protected getter runner : CliMate::Runner

    def category
      "Main"
    end

    macro category(text)
      def category
        {{text}}
      end
    end

    def desc
      "#{name} command"
    end

    macro desc(text)
      def desc
        {{text}}
      end
    end

    def usage
      "#{"Usage:".bold}\n  #{name} [OPTIONS] [ARGUMENTS]"
    end

    macro usage(text)
      def usage
        "#{"Usage:".bold}\n  #{{{text}}}"
      end
    end

    macro inherited
      CliMate::COMMANDS << {{@type}}
    end

    def initialize(@runner)
    end

    def prepare
      parser_options(@parser)
      @parser.unknown_args { |args| @arguments = args }
      @parser.missing_option do |msg|
        say "Missing option value: #{msg}".red
        show_usage
        stop
      end
      self
    end

    protected getter! options : CliMate::Options

    def execute(opts, args)
      @options = opts
      cmd = match_command(args) || (default.blank? ? nil : match_command(args.unshift(default)))
      if cmd
        parse_args(args) if parser
        cmd.execute(options, @arguments)
      else
        if parser
          @parser.invalid_option do |msg|
            say "Invalid option: #{msg}".red
            show_usage
            stop
          end
          parse_args(args, true)
        end
        if options.verbose > 1
          say "Args: #{@arguments.join(' ')}"
          say "Options:"
          say options.to_pretty_json
        end
        run(options, @arguments)
      end
    end

    def run(opts, args)
      say "This is empty <#{name.blue}> command.".green
    end

    def show_help
      say "#{desc}\n\n"
      show_usage
      if commands.size > 0
        say "\n#{"Sub-Commands:".bold}"
        show_subcommands_help("  ", 25)
      end
    end

    def show_usage
      say "#{usage}\n\n"
      opts_help = @parser.to_s
      say "#{"Options:".bold}\n#{opts_help}" unless opts_help.blank?
    end

    def show_subcommands_help(indent, margin)
      commands.sort_by(&.name).each do |c|
        say "#{indent}#{c.name.ljust(margin)}#{c.desc}"
        c.show_subcommands_help(indent + "... ", margin)
      end
    end
  end

  class HelpCommand < Command
    name  "help"
    category "Built-in General"
    usage "help [COMMAND]"
    desc  "Show general help or for specific command if command specified."

    def run(opts, args)
      target = runner
      while cmd = target.match_command(args)
        target = cmd
      end

      target.show_help
    end
  end

  class OptionsCommand < Command
    name  "options"
    category "Built-in General"
    usage "options"
    desc  "Set (optionally) and show current option values."

    def execute(opts, args)
      run(opts, @arguments)
    end

    def run(opts, args)
      runner.parser.parse(args)
      say runner.options.to_pretty_json
    end
  end

  class ExitCommand < Command
    category "Built-in General"
    desc "Exit REPL mode."

    def run(opts, args)
      LibReadline.write_history(runner.history_file_name)
      exit(0)
    end
  end
end
