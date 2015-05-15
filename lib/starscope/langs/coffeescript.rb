module Starscope::Lang
  module Coffeescript
    VERSION = 0

    def self.match_file(name)
      name.end_with?('.coffee')
    end

    def self.extract(file)
      # TODO
    end
  end
end
