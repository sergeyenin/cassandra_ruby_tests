require 'cassandra-cql'
class CqlStrategy
  include CassandraStrategy

  attr_accessor :keyspace

  def initialize(keyspace, connection_string, column_family="ThriftAcceleratedCQL", column_family_wide="ThriftAcceleratedCQLWide")
    @column_family = column_family
    @column_family_wide = column_family_wide
    self.connect!(keyspace, connection_string)
  end

  def connect!(keyspace, connection_string)
    @connection = CassandraCQL::Database.new(connection_string, {:keyspace => keyspace}, {:protocol => Thrift::BinaryProtocolAccelerated})
  end

  def write_test(wide_row_count=1000, wide_row_column_count=100, row_count=1000)
    raise "No cassandra connection found." unless @connection
    insert_wide_rows(wide_row_count, wide_row_column_count)
    insert_rows(row_count)
  end

  def read_test
    read_wide_rows(1000)
    read_rows(1000)
  end

  def setup_connection!(keyspace, column_family="ThriftAcceleratedCQL", column_family_wide="ThriftAcceleratedCQLWide")
    raise "No cassandra connection found." unless @connection
    @connection.execute("USE #{keyspace};")

    begin
      @connection.execute("DROP COLUMNFAMILY #{column_family}")
    rescue CassandraCQL::Error::InvalidRequestException => ex
    end

    begin
      @connection.execute("DROP COLUMNFAMILY #{column_family_wide}")
      rescue CassandraCQL::Error::InvalidRequestException => ex
    end

    @connection.execute("CREATE COLUMNFAMILY #{column_family} (id uuid PRIMARY KEY)")
    @connection.execute("CREATE COLUMNFAMILY #{column_family_wide} (id uuid PRIMARY KEY)")
  end

  private
  def insert_wide_rows(row_count, column_count)
    row_count.times do
      columns = [CassandraCQL::UUID.new]
      cql = "INSERT INTO #{column_family_wide} (id"
      column_count.times do |index|
        cql += ",'column_#{index.to_s}'"
        columns << Forgery(:basic).text
      end
      cql += ") VALUES (?#{',?' * column_count})"
      @connection.execute(cql, *columns)
    end
  end

  def insert_rows(row_count)
    row_count.times do
      @connection.execute("INSERT INTO #{@column_family} (id, email, password, first_name, last_name) VALUES (?, ?, ?, ?, ?)",\
                CassandraCQL::UUID.new,\
                Forgery(:internet).email_address,\
                Forgery(:basic).password,\
                Forgery(:name).first_name,\
                Forgery(:name).last_name\
               )
      end
  end

  def read_wide_rows(row_count)
    rows_read = 0
    @connection.execute("SELECT * FROM #{@column_family_wide}").fetch{|row| rows_read += 1}
    rows_read
  end

  def read_rows(row_count)
    rows_read = 0
    @connection.execute("SELECT * FROM #{@column_family}").fetch{|row| rows_read += 1}
    rows_read
  end
end