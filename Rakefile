require 'rubygems'
require 'bundler'
Bundler.setup

require 'rake'

#requiring all stuff
require 'benchmark'
require 'yaml'

require 'cassandra'
require 'right_support'

require File.expand_path("../lib/cassandra_ruby_test.rb",__FILE__)
COLUMN_FAMILIES = ["ThriftAccelerated", "ThriftAcceleratedWide", "Thrift", "ThriftWide"]
COLUMN_FAMILIES_CQL = ["ThriftAcceleratedCQL", "ThriftAcceleratedCQLWide"]
RightSupport::DB::CassandraModel.config = YAML.load_file(File.expand_path("../config/database.yml",__FILE__))

#make it keep silence in warnings
$VERBOSE = nil

if ['development', 'test'].include?(ENV['RACK_ENV'])
  LOGGER = Logger.new(STDERR)
else
  LOGGER = RightSupport::Log::SystemLogger.new('CassandraRubyTest')
end
environment = ENV["RACK_ENV"] || "production"
keyspace = "CassandraRubyTests_#{environment}"

desc "fire up a console with cassandra preloaded"
task :console do
  require 'irb'
  ARGV[0] = nil
  IRB.start
end

namespace :db do
  desc "clean database"
  task :clean do
    cassandra = Cassandra.new("system", RightSupport::DB::CassandraModel.config[environment]["server"])
    existing_keyspaces = cassandra.send(:client).describe_keyspaces.to_a.map{|k| k.name}.sort
    if existing_keyspaces.include? keyspace
      cassandra.send(:client).system_drop_keyspace(keyspace)
      puts "Existed keyspace #{keyspace} was successfully removed."
    end
  end

  desc "setup keyspaces and column families"
  task :setup=>[:clean] do

    puts "Setting up Keyspaces and ColumnFamilies...."


    cassandra = Cassandra.new("system", RightSupport::DB::CassandraModel.config[environment]["server"])
    existing_keyspaces = cassandra.send(:client).describe_keyspaces.to_a.map{|k| k.name}.sort

    #puts "current keyspaces:"
    #existing_keyspaces.each { |ks| puts " * #{ks}"}

    unless existing_keyspaces.include? keyspace
      puts "creating:"
      puts " * #{keyspace}"
      cf_defs = []
      COLUMN_FAMILIES.each do |cf|
        cf_defs << cf_def = Cassandra::ColumnFamily.new(:keyspace => keyspace, :name => cf,
          :column_type => 'Standard')
      end
      env = keyspace.split("_").last
      replication_factor = 1

      begin
        ks_def = Cassandra::Keyspace.new :name => keyspace,
          :strategy_class => "org.apache.cassandra.locator.SimpleStrategy",
          :replication_factor => replication_factor,
          :cf_defs => cf_defs
        cassandra.add_keyspace ks_def
      rescue => e
        puts " -> failed: #{e.message}"
      end
    end
  end

  desc "performs tests on avaible strategies"
  task :test=> [:setup] do
    clientTAS = ThriftAcceleratedStrategy.new(keyspace, RightSupport::DB::CassandraModel.config[environment]["server"])
    clientT = ThriftNotAcceleratedStrategy.new(keyspace, RightSupport::DB::CassandraModel.config[environment]["server"])
    clientCql = CqlStrategy.new(keyspace, RightSupport::DB::CassandraModel.config[environment]["server"])
    clientCql.setup_connection!(keyspace)
    Benchmark.bm(100) do |x|
        x.report("Thrift CQL accelarated write tests") {clientCql.write_test(10**3, 100, 10**3) }
        x.report("Thrift accelarated write tests") {clientTAS.write_test(10**3, 100, 10**3) }
        x.report("Thrift NOT accelarated write tests") {clientT.write_test(10**3, 100, 10**3) }
    end
    Benchmark.bm(100)do|x|
        x.report("Thrift CQL accelarated read tests") {clientCql.read_test(10**3, 10**3) }
        x.report("Thrift accelarated read tests") {clientTAS.read_test(10**3, 10**3) }
        x.report("Thrift NOT accelarated read tests") {clientT.read_test(10**3, 10**3) }
    end
  end

end

