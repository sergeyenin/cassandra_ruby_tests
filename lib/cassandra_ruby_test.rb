#helpers
$:.unshift File.expand_path("../cassandra_ruby_test",__FILE__)

require 's3_helper'
require 'syslog_io'
require 'test_column_family'

#strategies
$:.unshift File.expand_path("../cassandra_strategies",__FILE__)
require 'thrift_accelerated_strategy'
require 'thrift_not_accelerated_strategy'
require 'cql_strategy'