require 'cassandra_strategy'
require 'forgery'
class ThriftAcceleratedStrategy
  include CassandraStrategy

  def initialize(keyspace, connection_string, column_family="ThriftAccelerated", column_family_wide="ThriftAcceleratedWide")
    @column_family = column_family
    @column_family_wide = column_family_wide
    self.connect(keyspace, connection_string)
  end

  def connect(keyspace, connection_string)
    @connection = Cassandra.new(keyspace, connection_string, {:protocol => Thrift::BinaryProtocolAccelerated}) or raise "connect should be implemented in ConcreteStrategy"
  end

  def clean
      raise "clean should be implemented in CQL strategy"
  end

  def setup
      raise "setup should be implemented in  CQL strategy"
  end

  def write_test(wide_row_count=1000, wide_row_column_count=100, row_count=1000)
    insert_wide_rows(wide_row_count, wide_row_column_count)
    insert_rows(row_count)
  end


  def read_test
    read_wide_rows(1000)
    read_rows(1000)
  end


  private
  def insert_wide_rows(row_count, column_count)
    row_count.times do
     columns = {}
     column_count.times do |index|
       columns[SimpleUUID::UUID.new.to_s] = SimpleUUID::UUID.new.to_s
     end
     @connection.insert(@column_family_wide.intern, SimpleUUID::UUID.new.to_s, columns)
    end
  end

  def insert_rows(row_count)
    row_count.times do
      @connection.insert(@column_family.intern, SimpleUUID::UUID.new.to_s,
                            { 'email' => Forgery(:internet).email_address,
                              'password' => Forgery(:basic).password,
                              'first_name' => Forgery(:name).first_name,
                              'last_name' => Forgery(:name).last_name
                            }
                           )
    end
  end

  def read_wide_rows(row_count)
    rows_read = 0
    @connection.each(@column_family_wide.intern, :count=>1) do |row|
          rows_read += 1
          #return if row_count > rows_read
    end
  end

  def read_rows(row_count)
    rows_read = 0
    @connection.each(@column_family.intern) do |row|
      rows_read += 1
      #return if row_count > rows_read
    end
  end

end