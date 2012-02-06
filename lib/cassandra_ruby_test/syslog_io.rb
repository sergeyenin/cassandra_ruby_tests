require 'syslog'

# A quick-and-dirty IO-like object for logging to Syslog
class SyslogIO

  def initialize name, something_else, facility
    # fac_map from seattle.rb's SyslogLogger
    fac_map = {'user'=>8}
    (0..7).each { |i| fac_map['local'+i.to_s] = 128+8*i }
    @syslog = Syslog.open(name,something_else,fac_map[facility.to_s])
  end
  
  def puts message
    return if message == "\n"
    @syslog.warning message
  end

  def write message
    return if message == "\n"
    @syslog.warning message
  end

  def method_missing name, *args
    if @syslog.respond_to? name
      @syslog.send name, *args
    else
      super
    end
  end

end
