module Starscope
  module Lang
    module Vue
      VERSION = 1

      SCRIPT_START = '<script>'.freeze
      SCRIPT_END = '</script>'.freeze

      def self.match_file(name)
        name.end_with?('.vue')
      end

      def self.extract(_path, contents)
        in_script = false

        contents.lines.each_with_index do |line, line_no|
          line_no += 1 # zero-index to one-index

          if in_script
            if line.strip == SCRIPT_END
              in_script = false
            else
              yield Starscope::DB::FRAGMENT, :Javascript, frag: line, line_no: line_no
            end
          elsif line.strip == SCRIPT_START
            in_script = true
          end
        end
      end
    end
  end
end
