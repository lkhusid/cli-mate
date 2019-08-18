module CliMate::Helpers
  def ask
    STDIN.gets[0...-1]
  end

  def stop(code = 1)
    raise ExitException.new(code)
  end

  def say(*args)
    Output.say(*args)
  end

  def blurt(*args)
    Output.blurt(*args)
  end

  def silent(value)
    Output.silent = value
  end


  private class Output
    class_property silent = false

    def self.say(*args)
      puts *args unless @@silent
    end

    def self.blurt(*args)
      print *args unless @@silent
    end
  end

  class ExitException < Exception
    property code : Int32 = 0

    def initialize(@code : Int32)
    end
  end
end


class String
  class_property with_color = true

  def terminate_with(string : String)
    self[-string.size..-1] == string ? self : (self + string)
  end

  {% for name, code in {bold: "\e[1m", invert: "\e[7m", red: "\e[31m", yellow: "\e[33m", green: "\e[32m", blue: "\e[34m"} %}
    def {{name.id}}(background = nil)
      codex = {{code}}
      @@with_color ? "\e[0m#{"\e[7m" if background}#{codex}#{self}\e[0m" : self
    end
    def {{name.id}}!(background = nil)
      codex = {{code}}
      @@with_color ? "#{"\e[7m" if background}#{codex}#{self}" : self
    end
  {% end %}

  def super_split(separator : String, ignore_inside = '"', escape_char = '\\', include_blank = false, strip_ignore_inside = true)
    return super_split(/#{Regex.escape(separator)}/,
    ignore_inside: ignore_inside,
    escape_char: escape_char,
    include_blank: include_blank,
    strip_ignore_inside: strip_ignore_inside)
  end

  def super_split(separator : Regex, ignore_inside = '"', escape_char = '\\', include_blank = false, strip_ignore_inside = true) : Array(String)
    result = [] of String
    prev = 0
    ignore_regex = /(?<!#{Regex.escape(escape_char)})#{Regex.escape(ignore_inside)}/
    ignore_matches = self.scan(ignore_regex)
    ignore_count = 0
    self.scan(/#{separator}|$/).each do |m|
      while ignore_count < ignore_matches.size && ignore_matches[ignore_count].begin.as(Int32) < m.begin.as(Int32)
        ignore_count += 1
      end
      if ignore_count.even?
        token = self[prev...m.begin.as(Int32)]
        token = token[1..-2] if token[0] == ignore_inside && token[-1] == ignore_inside && token[-2] != escape_char
        result << token if include_blank || !token.blank?
        prev = m.end.as(Int32)
      end
    end
    return result
  end
end
