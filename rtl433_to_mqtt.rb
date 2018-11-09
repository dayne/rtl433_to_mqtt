#!/usr/bin/env ruby

require 'mqtt'
require 'json'
require 'pty'
require 'colored'
require 'yaml'

cfg = YAML.load_file('config.yml')

mqtt = MQTT::Client.connect(
  :host => cfg['server'],
  :port => cfg['port']
)

begin
  PTY.spawn("rtl_433 -G -F json") do |stdout, stdin, pid|
    begin
      stdout.each do |line|
        begin
          v = JSON.parse(line)
          v['ts'] = Time.now.getutc.to_i
          puts v.inspect.green
          mqtt.publish(cfg['topic'], v.to_json)
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
