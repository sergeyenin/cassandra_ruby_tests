require 'cassandra-cql'
class CqlStrategy
  include CassandraStrategy

  class << self
    def clean(keyspace, column_families)
      db = CassandraCQL::Database.new('127.0.0.1:9160')
      CassandraStrategy.drop_column_families(db, keyspace, column_families)
      CassandraStrategy.drop_keyspace(db, keyspace)
      db.disconnect!
    end

    def drop_column_families(db_conn, keyspace, column_families)
      begin
        db_conn.execute("use #{keyspace};")
        column_families.each do |cf|
          db_conn.execute("DROP COLUMNFAMILY #{cf};")
        end
      rescue CassandraCQL::Error::InvalidRequestException => ex
      end
    end

    def drop_keyspace(db_conn, keyspace)
      begin
        db_conn.execute("DROP KEYSPACE #{keyspace};")
      rescue CassandraCQL::Error::InvalidRequestException => ex
      end
    end
  end

  def connect
    raise "connect should be implemented in ConcreteStrategy"
  end

  def setup
    raise "setup should be implemented in ConcreteStrategy"
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