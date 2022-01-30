require_relative '../test_helper'

describe Starscope::Queryable do
  SAMPLE_RECORDS = [
    { name: [:"[abc"], foo: 'baz' },
    { name: [:"not a match"], foo: 'bar', x: 'y' },
    { name: [:a, :b, :c, :d], file: :somefile }
  ].freeze

  class MockQuerable
    include Starscope::Queryable
    def initialize
      @tables = {
        mytable: SAMPLE_RECORDS,
        empty_table: []
      }
      @meta = {
        files: {
          somefile: {
            lang: :ruby
          }
        }
      }
    end
  end

  before do
    @mock = MockQuerable.new
  end

  it 'must handle empty input' do
    _(@mock.query(:empty_table, 'foo')).must_be_empty
  end

  it 'must handle scoped queries' do
    _(@mock.query(:mytable, 'a::b::')).must_equal [SAMPLE_RECORDS[2]]
  end

  it 'must handle regex queries' do
    _(@mock.query(:mytable, 'a[bc]{2}')).must_equal [SAMPLE_RECORDS[0]]

    _(@mock.query(:mytable, 'a.*d')).must_equal [SAMPLE_RECORDS[2]]
  end

  it 'must handle malformed regexes' do
    _(@mock.query(:mytable, '[abc')).must_equal [SAMPLE_RECORDS[0]]
  end

  it 'must handle simple filters' do
    _(@mock.query(:mytable, '.*', foo: 'bar')).must_equal [SAMPLE_RECORDS[1]]
  end

  it 'must handle multiple filters' do
    _(@mock.query(:mytable, '.*', foo: 'bar', x: 'y')).must_equal [SAMPLE_RECORDS[1]]
    _(@mock.query(:mytable, '.*', foo: 'bar', x: 'nope')).must_be_empty
  end

  it 'must handle filters on file properties' do
    _(@mock.query(:mytable, '.*', lang: 'ruby')).must_equal [SAMPLE_RECORDS[2]]
  end
end
