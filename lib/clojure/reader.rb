module Clojure
  # read Clojure as Ruby's data-structures
  class Reader
    def initialize(source)
      @source = source
      @io = StringIO.new source
      @ast = []
      loop do
        break if eof?
        r = read_next
        @ast << r if r
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
      when /\;/ then skip_comment
      when /\d/ then read_number
      when /\(/ then read_form
      when /\[/ then read_form till: "]", into: ["vector"]
      when /\{/ then read_form till: "}", into: ["hash-map"]
      when /\:/ then read_keyword
      when /\"/ then read_string
      when /\'/ then read_quote
      when /\S/ then read_symbol
      end
    end

    def skip_char
      next_char
      nil
    end

    def skip_comment
      next_char until cursor == "\n" || eof?
      nil
    end

    def read_form(till: ")", into: [])
      opening = cursor
      skip_char # opening parenthesis
      ast = into
      until cursor == till
        raise Exception, "Unbalanced #{opening}#{till}" if eof?
        r = read_next
        ast << r if r
      end
      skip_char # closing parenthesis
      ast
    end

    def read_number
      n = cursor
      while next_char.match /[\d|.]/
        n << cursor
      end
      Integer(n) rescue Float(n)
    end

    def read_keyword
      next_char
      k = cursor
      while next_char.match /\w|\.|#|-|_/
        k << cursor
      end
      k.to_sym
    end

    def read_quote
      skip_char # '
      ["quote", read_next]
    end

    def read_string
      s = ""
      s << cursor until next_char == '"'
      next_char
      ['str', ['quote', s]]
    end

    def read_symbol
      symbol = cursor
      while next_char.match /\w|-|\.|\?|\+|\//
        symbol << cursor
      end
      symbol
    end
  end
end
