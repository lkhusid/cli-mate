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
  end
