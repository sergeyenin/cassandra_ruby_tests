module Thrift
  module ThriftSocketPatch
    def self.included(base)
      base.send(:remove_method, :open)
      base.send(:include, InstanceMethods)
    end

    module InstanceMethods
      def open
        begin
          addrinfo = ::Socket::getaddrinfo(@host, @port).first
          @handle = ::Socket.new(addrinfo[4], ::Socket::SOCK_STREAM, 0)
          sockaddr = ::Socket.sockaddr_in(addrinfo[1], addrinfo[3])
          begin
            @handle.connect_nonblock(sockaddr)
          rescue Errno::EINPROGRESS
            #unless IO.select(nil, [ @handle ], nil, @timeout)
            #  raise TransportException.new(TransportException::NOT_OPEN, "Connection timeout to #{@desc}")
            #end
            resp = IO.select(nil, [ @handle ], nil, @timeout)
            begin
              @handle.connect_nonblock(sockaddr)
            rescue Errno::EISCONN
            end
          end
          @handle
        rescue StandardError => e
          raise TransportException.new(TransportException::NOT_OPEN, "Could not connect to #{@desc}: #{e}")
        end
      end
    end
  end
end