module CassandraStrategy

  attr_accessor :connection, :column_family, :column_family_wide

  def connect!
    raise "connect should be implemented in ConcreteStrategy"
  end

  def write_test
    raise "populate should be implemented in ConcreteStrategy"
  end

  def read_test
    raise "read_test should be implemented in ConcreteStrategy"
  end

  private
  def insert_wide_rows
  end

  def insert_rows
  end

  def read_wide_rows
  end

  def read_rows
  end
end