module Sprockets
  class SourceLine
    attr_reader :source_file, :line, :number

    def initialize(source_file, line, number)
      @source_file = source_file
      @line = line
      @number = number
    end

    def comment
      @comment ||= line[/^\s*\/\/(.*)/, 1]
    end

    def comment?
      !!comment
    end

    def comment!
      @comment = line
    end

    def begins_multiline_comment?
      line =~ /^\s*\/\*(.*)/
    end

    def begins_pdoc_comment?
      line =~ /^\s*\/\*\*(.*)/
    end

    def ends_multiline_comment?
      line =~ /^(.*)\*\/\s*/
    end

    def ends_pdoc_comment?
      line =~ /^(.*)\*\*\/\s*/
    end

    def require
      @require ||= (comment || "")[/^=\s+require\s+(#{QUOTED}|<(.*?)>)\s*$/, 1]
    end
    
    def require?
      !!require
    end
    
    def provide
      @provide ||= (comment || "")[/^=\s+provide\s+#{QUOTED}(?:\sas\s#{QUOTED})?\s*$/, 1]
    end
    
    def provide?
      !!provide
    end
    
    def alias
      @alias ||= (comment || "")[/^=\s+provide\s+#{QUOTED}\sas\s#{QUOTED}*$/, 2]
    end
    
    def alias?
      !!self.alias
    end
    
    def inspect
      "line #@number of #{@source_file.pathname}"
    end
    
    def to_s(constants = source_file.environment.constants)
      result = line.chomp
      interpolate_constants!(result, constants)
      strip_trailing_whitespace!(result)
      result + $/
    end
    
    protected
      QUOTED = /(?:\"|\')(.*?)(?:\"|\')/ # non-capturing grouping
    
      def interpolate_constants!(result, constants)
        result.gsub!(/<%=(.*?)%>/) do
          constant = $1.strip
          if value = interpret_constant(constant, constants)
            value
          else
            raise UndefinedConstantError, "couldn't find constant `#{constant}' in #{inspect}"
          end
        end
      end
      
      def interpret_constant(constant, constants)
        chain = constant.split('.')
        chain.inject(constants[chain.shift]) do |a, method|
          a.send(method)
        end
      end
      
      def strip_trailing_whitespace!(result)
        result.gsub!(/\s+$/, "")
      end
  end
end
