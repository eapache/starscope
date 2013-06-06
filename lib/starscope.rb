require "starscope/version"
require "starscope/parsers/ruby"
require "starscope/db"

module StarScope
  class StarScope
    def initialize
      @db = DB.new
      @parser = Parsers::Ruby.new
      @parser.db = @db
    end

    def build_db(directory)
      Dir["#{directory}/**/*"].each do |file|
        @parser.parse(file)
      end
    end

    def print_db
      puts @db
    end
  end
end
