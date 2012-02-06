require 'syslog'
require 'logger'

##
# This SyslogLogger is a slightly hacked SyslogLoggerLogger 
# SyslogLogger is a Logger work-alike that logs via syslog instead of to a
# file.  You can add SyslogLogger to your Rails production environment to
# aggregate logs between multiple machines.
#
# By default, SyslogLogger uses the program name 'rails', but this can be
# changed via the first argument to SyslogLogger.new.
#
# NOTE! You can only set the SyslogLogger program name when you initialize
# SyslogLogger for the first time.  This is a limitation of the way
# SyslogLogger uses syslog (and in some ways, a the way syslog(3) works).
# Attempts to change SyslogLogger's program name after the first
# initialization will be ignored.
#
# = Sample usage with Rails
# 
# == config/environment/production.rb
#
# Add the following lines:
# 
#   require 'production_log/syslog_logger'
#   RAILS_DEFAULT_LOGGER = SyslogLogger.new
#
# == config/environment.rb
#
# In 0.10.0, change this line:
# 
#   RAILS_DEFAULT_LOGGER = Logger.new("#{RAILS_ROOT}/log/#{RAILS_ENV}.log")
#
# to:
#
#   RAILS_DEFAULT_LOGGER ||= Logger.new("#{RAILS_ROOT}/log/#{RAILS_ENV}.log")
#
# Other versions of Rails should have a similar change.
#
# == /etc/syslog.conf
#
# Add the following lines:
# 
#  !rails
#  *.*                                             /var/log/production.log
#
# Then touch /var/log/production.log and signal syslogd with a HUP
# (killall -HUP syslogd, on FreeBSD).
#
# == /etc/newsyslog.conf
#
# Add the following line:
# 
#   /var/log/production.log                 640  7     *    @T00  Z
# 
# This creates a log file that is rotated every day at midnight, gzip'd, then
# kept for 7 days.  Consult newsyslog.conf(5) for more details.
#
# Now restart your Rails app.  Your production logs should now be showing up
# in /var/log/production.log.  If you have mulitple machines, you can log them
# all to a central machine with remote syslog logging for analysis.  Consult
# your syslogd(8) manpage for further details.

class SyslogLogger

    ##
    # Maps Logger warning types to syslog(3) warning types.

    LOGGER_MAP = {
        :unknown => :alert,
        :fatal   => :err,
        :error   => :warning,
        :warn    => :notice,
        :info    => :info,
        :debug   => :debug,
    }

    ##
    # Maps Logger log levels to their values so we can silence.

    LOGGER_LEVEL_MAP = {}

    LOGGER_MAP.each_key do |key|
        LOGGER_LEVEL_MAP[key] = Logger.const_get key.to_s.upcase
    end

    ##
    # Maps Logger log level values to syslog log levels.

    LEVEL_LOGGER_MAP = {}

    LOGGER_LEVEL_MAP.invert.each do |level, severity|
        LEVEL_LOGGER_MAP[level] = LOGGER_MAP[severity]
    end

    ## 
    # Maps facilities to numeric values
    FAC_MAP = {'user'=>8}
    (0..7).each { |i| FAC_MAP['local'+i.to_s] = 128+8*i }
    
    ##
    # Builds a logging method for level +meth+.

    def self.log_method(meth)
        eval <<-EOM, nil, __FILE__, __LINE__ + 1
            def #{meth}(message = nil)
                return true if #{LOGGER_LEVEL_MAP[meth]} < @level
                if message
                  puts clean(message)
                  SYSLOG.#{LOGGER_MAP[meth]} clean(message)
                elsif block_given?
                  message = yield
                  puts clean(message)
                  SYSLOG.#{LOGGER_MAP[meth]} clean(message)
                end
                return true
            end
        EOM
    end

    # Builds a concenience check method for checking the level of logs. i.e., 'debug?', 'info?'...
    def self.log_check_method(meth)
        eval <<-EOM, nil, __FILE__, __LINE__ + 1
            def #{meth}?
                @level <= Logger::#{meth.to_s.upcase}
            end
        EOM
    end    
    
    LOGGER_MAP.each_key do |level|
        log_method level
        log_check_method level 

        # For compatibility with Merb.logger
        alias_method "#{level}!".to_sym, level
    end


    ##
    # Log level for Logger compatibility.

    attr_accessor :level

    
    ##
    # Fills in variables for Logger compatibility.  If this is the first
    # instance of SyslogLogger, +program_name+ may be set to change the logged
    # program name.
    #
    # Due to the way syslog works, only one program name may be chosen.

    def initialize(program_name = 'merb', facility = 'user')
      @level = Logger::DEBUG
      return if defined? SYSLOG
      if Syslog.opened?
        self.class.const_set :SYSLOG, Syslog
      else
        self.class.const_set :SYSLOG, Syslog.open(program_name, nil, FAC_MAP[facility.to_s])
      end
    end

    ##
    # Almost duplicates Logger#add.  +progname+ is ignored.

    def add(severity, message = nil, progname = nil, &block)
        severity ||= Logger::UNKNOWN
        return true if severity < @level
        message = clean(message || block.call)
        SYSLOG.send LEVEL_LOGGER_MAP[severity], clean(message)
        return true
    end

    ##
    # Allows messages of a particular log level to be ignored temporarily.
    #
    # Can you say "Broken Windows"?

    def silence(temporary_level = Logger::ERROR)
        old_logger_level = @level
        @level = temporary_level 
        yield
    ensure
        @level = old_logger_level
    end


    # For compatibility with Merb.logger
    def flush
      nil
    end
    
    # :api: public
    def verbose!(message, level = :warn)
      send("#{level}!", message)
    end

    # :api: public
    def verbose(message, level = :warn)
      send(level, message)
    end

    def facility
      value = SYSLOG.facility
      name, _ = FAC_MAP.find { |k,v| v == value }
      name
    end

    def facility=(new_facility)
      puts "SyslogLogger: switching facility from #{self.facility} to #{new_facility}"
      program_name = SYSLOG.ident
      SYSLOG.close
      self.class.send :remove_const, :SYSLOG
      self.class.const_set :SYSLOG, Syslog.open(program_name, nil, FAC_MAP[new_facility.to_s])
    end

    private

    ##
    # Clean up messages so they're nice and pretty.

    def clean(message)
      message = message.to_s.dup
      message.strip!
      message.gsub!(/%/, '%%') # syslog(3) freaks on % (printf)
      message.gsub!(/\e\[[^m]*m/, '') # remove useless ansi color codes
      return message
    end
    
end

