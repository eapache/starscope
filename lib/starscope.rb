require "starscope/version"
require "starscope/parsers/ruby"

module StarScope
  def self.build_db
    files = Dir["**/*"]
    files.each do |file|
      Parsers::Ruby.parse(file)
    end
  end
end
