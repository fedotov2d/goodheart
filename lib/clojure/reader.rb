# frozen_string_literal: true

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
      when :eof then nil
      when /\s/ then skip_char
      when /,/ then skip_char
      when /;/ then skip_comment
      when /\d/ then read_number
      when /\(/ then read_form
      when /\[/ then read_form till: "]", into: ["vector"]
      when /\{/ then read_form till: "}", into: ["hash-map"]
      when /:/ then read_keyword
      when /"/ then read_string
      when /'/ then read_quote
      when /\#/ then read_special
      when /\S/ then read_symbol
      else raise StandardError, "Unexpected symbol: #{cursor}"
      end
    end
    # rubocop:enable Metrics/CyclomaticComplexity
    # rubocop:enable Metrics/AbcSize

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

    def read_number
      n = cursor
      n << cursor while next_char.match(/[\d|.]/)
      begin
        Integer(n)
      rescue StandardError
        Float(n)
      end
    end

    def read_keyword
      next_char
      k = cursor
      k << cursor while next_char.match(/\w|\.|#|-|_/)
      k.to_sym
    end

    def read_quote
      skip_char # '
      ["quote", read_next]
    end

    # rubocop:disable Metrics/AbcSize
    def read_string
      next_char
      if cursor == '"'
        next_char
        return ["str", ["quote", ""]]
      end
      s = cursor.dup
      prev = cursor
      until next_char == '"' && prev != "\\"
        if cursor == "\\"
          # no-op
        elsif cursor == '"'
          s << cursor
        elsif prev == "\\"
          s << "\\#{cursor}"
        else
          s << cursor
        end
        prev = cursor
      end
      next_char
      ["str", ["quote", s]]
    end
    # rubocop:enable Metrics/AbcSize

    def read_symbol
      symbol = cursor
      symbol << cursor while next_char.match(%r{\w|-|\.|\?|\+|/})
      symbol
    end
  end
end
