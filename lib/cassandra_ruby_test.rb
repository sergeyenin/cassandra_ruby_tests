#helpers
$:.unshift File.expand_path("../cassandra_ruby_test",__FILE__)

require 's3_helper'
require 'syslog_io'
require 'test_column_family'

#patches
$:.unshift File.expand_path("../patches",__FILE__)

require 'thrift_socket_patch'

#monkey patching for thrift on Jruby
#for details, please, see https://github.com/twitter/cassandra/issues/93
if defined?(Thrift.java)
  unless Thrift::Socket.included_modules.include? Thrift::ThriftSocketPatch
    Thrift::Socket.send(:include, Thrift::ThriftSocketPatch)
  end
end

#strategies
$:.unshift File.expand_path("../cassandra_strategies",__FILE__)
#require 'thrift_accelerated_strategy'
require 'thrift_not_accelerated_strategy'
require 'cql_strategy'