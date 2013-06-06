class StarScope::Parser

  def set_db(db)
    @db = db
  end

  def func_called(name, loc)
    @db.table[:calls].add(name, loc)
  end

end
