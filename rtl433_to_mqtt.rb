#!/usr/bin/env ruby

require 'mqtt'
require 'json'
require 'pty'
require 'colored'
require 'yaml'
require 'logger'

if ARGV.delete("-l")
  logger = Logger.new('logs/rtl433.log','daily')
  logger.formatter = proc do |sev, datetime, progname, msg|
    # sev and progname not helpful. datetime already in msg so just
    # slam the json messages in log file - one msg line
    "#{msg}\n" 
  end
end

if File.exists?('config.yml')
  cfg = YAML.load_file('config.yml')['rtl_433']
else
  cfg = YAML.load_file('config.yml.example')['rtl_433']
end

mqtt = MQTT::Client.connect(
  :host => cfg['host'],
  :port => cfg['port'],
  :username => cfg['username'],
  :password => cfg['password']
)

begin
  PTY.spawn("rtl_433 -F json -M UTC -f #{cfg['rtl_freq']}") do |stdout, stdin, pid|
    begin
      last_line = ""
      stdout.each do |line|
        begin
          # some sensors send the same message multiple times - skip dups
          next if line == last_line
          v = JSON.parse(line)
          v['ts'] = Time.now.getutc.to_i
          puts v.inspect.green
          mqtt.publish(cfg['topic'], v.to_json)
          logger.info(v.to_json) if logger
          last_line = line
        rescue JSON::ParserError
          puts "Unparsable: #{line}".yellow
        end
      end
    rescue Errno::EIO
    end
  end
rescue PTY::ChildExited
  puts "rtl_433 process exited"
end
