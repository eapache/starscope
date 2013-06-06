class StarScope::DB

  def add_ref(tblname, value, location)
    table[tblname] ||= {}
    table[tblname][value.simple] ||= []
    table[tblname][value.simple] << [value, location]
  end

  def tables
    table.keys
  end

  def to_s
    "TODO"
  end
  private

  def table
    @table ||= {}
  end

end
