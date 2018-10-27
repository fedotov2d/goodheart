module Clojure
  # read Clojure as Ruby's data-structures
  class Reader
    def initialize(source)
      @source = source
      @io = StringIO.new source
      @ast = []
      loop do
        break if eof?
        @ast << read_next
      end
      true
    end

    def inspect
      @ast
    end

    attr_reader :ast

    def cursor
      @cursor || next_char
    end

    def eof?
      @cursor == :eof
    end

    def next_char
      @cursor = @io.getc || :eof
    end

    def read_next
      # puts "reading next"
      # puts "-> #{cursor}"
      case cursor
      when :eof then return
      when /\s/ then skip_char
      when /\,/ then skip_char
      when /\(/ then read_list
      end
    end

    def skip_char
      next_char
      nil
    end

    def read_list
      # puts "reading list"
      # puts "-> #{cursor}"
      skip_char # (
      ast = []
      until cursor == ')'
        raise Exception, "Unbalanced ()" if eof?
        r = read_next
        ast << r if r
      end
      skip_char # )
      ast
    end
  end
end
