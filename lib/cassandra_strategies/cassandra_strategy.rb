module CassandraStrategy

  attr_accessor :connection

  def connect
    raise "connect should be implemented in ConcreteStrategy"
  end

  def clean
    raise "clean should be implemented in ConcreteStrategy"
  end

  def setup
    raise "setup should be implemented in ConcreteStrategy"
  end

  def populate
    raise "populate should be implemented in ConcreteStrategy"
  end

  def truncate
    raise "truncate should be implemented in ConcreteStrategy"
  end

end