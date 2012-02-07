module CassandraStrategy

  attr_accessor :connection, :column_family, :column_family_wide

  def connect
    raise "connect should be implemented in ConcreteStrategy"
  end

  def clean
    raise "clean should be implemented in ConcreteStrategy"
  end

  def setup
    raise "setup should be implemented in ConcreteStrategy"
  end

  def truncate
    raise "truncate should be implemented in ConcreteStrategy"
  end

  def write_test
    raise "populate should be implemented in ConcreteStrategy"
  end

  private
  def insert_wide_rows(row_count, column_count)
  end

  def insert_rows
  end

  def read_wide_rows
  end

  def read_rows
  end
end