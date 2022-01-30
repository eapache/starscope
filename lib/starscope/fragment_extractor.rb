module Starscope
  class FragmentExtractor
    def initialize(lang, frags)
      @child = Starscope::Lang.const_get(lang)
      @frags = frags
    end

    def extract(path, _text)
      compiled_text = @frags.map { |f| f.delete(:frag).strip }.join("\n")

      @child.extract(path, compiled_text) do |tbl, name, args|
        args.merge!(@frags[args[:line_no] - 1]) if args[:line_no]
        yield tbl, name, args
      end

      # TODO: translate metadata?
    end

    def name
      @child.name
    end
  end
end
