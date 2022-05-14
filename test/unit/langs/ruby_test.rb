require_relative '../../test_helper'

describe Starscope::Lang::Ruby do
  before do
    @db = {}
    Starscope::Lang::Ruby.extract(RUBY_SAMPLE, File.read(RUBY_SAMPLE)) do |tbl, name, args|
      @db[tbl] ||= []
      @db[tbl] << Starscope::DB.normalize_record(RUBY_SAMPLE, name, args)
    end
  end

  it 'must match ruby files' do
    _(Starscope::Lang::Ruby.match_file(RUBY_SAMPLE)).must_equal true
    _(Starscope::Lang::Ruby.match_file('bin/starscope')).must_equal true
  end

  it 'must not match non-ruby files' do
    _(Starscope::Lang::Ruby.match_file(GOLANG_SAMPLE)).must_equal false
    _(Starscope::Lang::Ruby.match_file(EMPTY_FILE)).must_equal false
  end

  it 'must identify function definitions' do
    _(@db.keys).must_include :defs
    defs = @db[:defs].map { |x| x[:name][-1] }

    _(defs).must_include :DB
    _(defs).must_include :NoTableError
    _(defs).must_include :load
    _(defs).must_include :update
    _(defs).must_include :files_from_path
    _(defs).must_include :get_lastfile
  end

  it 'must identify constant definitions' do
    _(@db.keys).must_include :defs
    defs = @db[:defs].map { |x| x[:name][-1] }

    _(defs).must_include :PBAR_FORMAT
    _(defs).must_include :SOME_INVALID_ENCODING
  end

  it 'must identify endings' do
    _(@db.keys).must_include :end
    _(@db[:end].count).must_equal 14
  end

  it 'must identify function calls' do
    _(@db.keys).must_include :calls
    calls = @db[:calls].group_by { |x| x[:name][-1] }

    _(calls.keys).must_include :add_file
    _(calls.keys).must_include :each
    _(calls[:add_file].count).must_equal 3
    _(calls[:each].count).must_equal 8
  end

  it 'must identify variable assignments' do
    _(@db.keys).must_include :assigns
    assigns = @db[:assigns].group_by { |x| x[:name][-1] }

    _(assigns.keys).must_include :pbar
    _(assigns.keys).must_include :PBAR_FORMAT
    _(assigns.keys).must_include :foo
    _(assigns[:pbar].count).must_equal 2
    _(assigns[:PBAR_FORMAT].count).must_equal 1
    _(assigns[:foo].count).must_equal 1

    _(assigns.keys).wont_include :'='
    _(assigns.keys).wont_include :<
  end

  it 'must identify variable and constant reads' do
    _(@db.keys).must_include :reads
    reads = @db[:reads].map { |x| x[:name][-1] }

    _(reads).must_include :Go
    _(reads).must_include :Ruby
    _(reads).must_include :DB_FORMAT
    _(reads).must_include :UnknownDBFormatError
    _(reads).must_include :path
    _(reads).must_include :entry
    _(reads).must_include :file
    _(reads).must_include :@files
  end
end
