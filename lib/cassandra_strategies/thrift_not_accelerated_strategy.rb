require 'thrift_accelerated_strategy'
require 'forgery'
class ThriftNotAcceleratedStrategy < ThriftAcceleratedStrategy
  include CassandraStrategy

  def initialize(keyspace, connection_string, column_family="Thrift", column_family_wide="ThriftWide")
    @column_family = column_family
    @column_family_wide = column_family_wide
    self.connect!(keyspace, connection_string)
  end

  def connect!(keyspace, connection_string)
    @connection = Cassandra.new(keyspace, connection_string) or raise "connect should be implemented in ConcreteStrategy"
  end

end