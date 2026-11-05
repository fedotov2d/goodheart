# frozen_string_literal: true

require "stringio"

module Clojure
  # read Clojure as Ruby's data-structures
  class Reader
    SYMBOL_CHAR = %r{\w|-|\.|\?|\+|/|>|<|=|\*|!}

    def initialize(source)
      @source = source
      @io = StringIO.new source
      @ast = []
      loop do
        break if eof?

        r = read_next
        @ast << r if r
      end
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

    # rubocop:disable Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/AbcSize
    def read_next
      # puts "reading next"
      # puts "-> #{cursor}"
      case cursor
      when :eof   then nil
      when /\s|,/ then skip_char
      when /;/    then skip_comment
      when /\d/   then read_number
      when /[+-]/ then read_signed
      when /\(/   then read_form
      when /\[/   then read_form till: "]", into: ["vector"]
      when /\{/   then read_form till: "}", into: ["hash-map"]
      when /:/    then read_keyword
      when /"/    then read_string
      when /'/    then read_quote
      when /\#/   then read_special
      when /\S/   then read_symbol
      else raise StandardError, "Unexpected symbol: #{cursor}"
      end
    end
    # rubocop:enable Metrics/CyclomaticComplexity
    # rubocop:enable Metrics/AbcSize

    def read_signed
      sign = +cursor.to_s
      if next_char != :eof && cursor.match?(/\d/)
        read_number(sign)
      else
        read_symbol(sign)
      end
    end

    def read_special
      case next_char
      when /_/ then read_sexp_comment
      else raise StandardError, "Unknown token: ##{cursor}"
      end
    end

    def read_sexp_comment
      next_char
      read_next
      nil
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
        raise StandardError, "Unbalanced #{opening}#{till}" if eof?

        r = read_next
        ast << r if r
      end
      skip_char # closing parenthesis
      ast
    end

    def read_number(prefix="")
      n = "#{prefix}#{cursor}"
      n << cursor while next_char != :eof && !cursor.match?(/[\s,()\[\]{}";]/)
      parse_number(n)
    end

    def parse_number(token)
      case token
      when /\A[+-]?\d+\z/
        Integer(token)
      when /\A[+-]?\d+\.\d+\z/
        Float(token)
      when %r{\A[+-]?\d+/\d+\z}
        Rational(token)
      else
        raise StandardError, "Invalid number: #{token}"
      end
    end

    def read_keyword
      next_char
      k = +cursor.to_s
      k << cursor while next_char != :eof && cursor.match?(/\w|\.|#|-|_/)
      k.to_sym
    end

    def read_quote
      skip_char # '
      ["quote", read_next]
    end

    # rubocop:disable-next Metrics/AbcSize
    def read_string
      next_char
      if cursor == '"'
        next_char
        return ["str", ["quote", ""]]
      end
      s = cursor.dup
      prev = cursor
      until next_char == '"' && prev != "\\"
        if cursor != "\\"
          s << if prev == "\\" && cursor != '"'
                 "\\#{cursor}"
               else
                 cursor
               end
        end
        prev = cursor
      end
      next_char
      ["str", ["quote", s]]
    end

    def read_symbol(symbol=+"")
      if symbol.empty?
        symbol << cursor
        next_char
      end
      while !eof? && cursor.match?(SYMBOL_CHAR)
        symbol << cursor
        next_char
      end
      symbol
    end
  end
end
