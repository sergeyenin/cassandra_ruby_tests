require 'rubygems'
require 'bundler'
Bundler.setup

require 'rake'

#requiring all stuff

require 'yaml'


require 'cassandra/0.7'
require 'right_support'

require File.expand_path("../lib/cassandra_ruby_test.rb",__FILE__)

RightSupport::DB::CassandraModel.config = YAML.load_file(File.expand_path("../config/database.yml",__FILE__))

#dirty hack to make right_support think we are inside some middleware
ENV["RACK_ENV"] = ENV["RACK_ENV"] || "production"

if ['development', 'test'].include?(ENV['RACK_ENV'])
  LOGGER = Logger.new(STDERR)
else
  LOGGER = RightSupport::Log::SystemLogger.new('CassandraRubyTest')
end

desc "fire up a console with cassandra preloaded"
task :console do
  require 'irb'
  ARGV[0] = nil
  IRB.start
end

namespace :db do
  desc "clean database"
  task :clean do
    puts "Removing existed keyspace"
    environment = ENV["RACK_ENV"] || "development"
    keyspace = "CassandraRubyTest_#{environment}"
    cassandra = Cassandra.new "system"
    existing_keyspaces = cassandra.send(:client).describe_keyspaces.to_a.map{|k| k.name}.sort

    if existing_keyspaces.include? keyspace
      cassandra.remove(keyspace.intern)
    end
  end

  desc "setup keyspaces and column families"
  task :setup=>[:clean] do

    puts "Setting up Keyspaces and ColumnFamilies...."
    environment = ENV["RACK_ENV"] || "development"
    keyspace = "CassandraRubyTest_#{environment}"

    cassandra = Cassandra.new "system"
    existing_keyspaces = cassandra.send(:client).describe_keyspaces.to_a.map{|k| k.name}.sort

    #puts "current keyspaces:"
    #existing_keyspaces.each { |ks| puts " * #{ks}"}

    unless existing_keyspaces.include? keyspace
      puts "creating:"
      puts " * #{keyspace}"
      cf_def = Cassandra::ColumnFamily.new :keyspace => keyspace,
      :name => "TestColumnFamily",
      :comparator_type => "LongType"

      env = keyspace.split("_").last
      replication_factor = 1

      begin
        ks_def = Cassandra::Keyspace.new :name => keyspace,
          :strategy_class => "org.apache.cassandra.locator.SimpleStrategy",
          :replication_factor => replication_factor,
          :cf_defs => [cf_def]
        cassandra.add_keyspace ks_def
      rescue => e
        puts " -> failed: #{e.message}"
      end
    end
  end

  desc "populate Keyspace with 10mln values"
  task :populate=> [:setup] do
    n = 10 * 10**6
    time = Benchmark.measure do
      (1..n).each do |i|
        TestColumnFamily.append(sprintf("%07d", i), sprintf("%07d", i))
      end
    end
    puts time
  end

end

