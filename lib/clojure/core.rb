module Clojure
  class Core < Clojure::Lib
    define "+", ->(_ctx, args) { args.reduce(:+) }
    define "-", ->(_ctx, args) { args.reduce(:-) }
    define "*", ->(_ctx, args) { args.reduce(:*) }
    define "/", ->(_ctx, args) { args.reduce(:/) }

    define "=", ->(_ctx, args) { !!args.reduce { |x,y| x == y ? x : break } }
    define ">", ->(_ctx, args) { !!args.reduce { |x,y| x >  y ? x : break } }
    define "<", ->(_ctx, args) { !!args.reduce { |x,y| x <  y ? x : break } }

    define "vector", ->(_ctx, args) { Array[*args] }
    define "hash-map", ->(_ctx, args) { Hash[*args] }

    define "str", ->(_ctx, args) { args.map(&:to_s).join }
    define "quote", ->(_ctx, args) { args }
  end
end