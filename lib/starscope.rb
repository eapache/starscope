require "starscope/version"
require "starscope/parsers/ruby"
require "starscope/db"

module StarScope
  def self.build_db
    db = DB.new
    parser = Parsers::Ruby.new
    parser.set_db(db)
    Dir["**/*"].each do |file|
      parser.parse(file)
    rescue
      puts "Error parsing #{file}!"
    end
  end
end
