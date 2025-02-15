#!/usr/bin/env ruby

require 'mqtt'
require 'json'
require 'open3'
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

if File.exist?('config.yml')
  puts "Loading config.yml".green
  cfg = YAML.load_file('config.yml')['rtl_433']
else
  puts "Falling back to config.yml.example configuration".yellow
  cfg = YAML.load_file('config.yml.example')['rtl_433']
end

puts "Connecting to mqtt://#{cfg['host']}:#{cfg['port']}#{cfg['topic']}"
mqtt = MQTT::Client.connect(
  :host => cfg['host'],
  :port => cfg['port'],
  :username => cfg['username'],
  :password => cfg['password']
)

# if rtl_freq not set then don't specify a specific 
# frequency and let default behaivor happen
rtl_freq_option = cfg['rtl_freq'] ? "-f #{cfg['rtl_freq']}" : ""
rtl_command="rtl_433 -F json -M UTC #{rtl_freq_option}"

puts "Launching rtl_433 sub-process: #{rtl_command}"

threads = []
message_count = 0
tuner_type = ""
rtl_version = ""

Open3.popen3(rtl_command) do |stdin, stdout, stderr, thread|
  trap("INT") do
    puts "\nCaught Ctrl+C ... Shutting down gracefully...".green
    puts "Processed #{message_count} messages during this run".green 
    threads.each(&:kill)  # Kill running threads
    thread.kill           # Kill the process thread
    exit(0)
  end

  threads << Thread.new do
    last_line = ""
    stdout.each_line do |line|
      begin
        # some sensors send the same message multiple times - skip dups
        next if line == last_line
        v = JSON.parse(line)
        v['ts'] = Time.now.getutc.to_i
        puts v.inspect.green
        mqtt.publish(cfg['topic'], v.to_json)
        logger.info(v.to_json) if logger
        last_line = line
        message_count += 1
      rescue JSON::ParserError
        puts "Unparsable: #{line}".red
      end
    end
  end

  threads << Thread.new do 
    stderr.each_line do |line|
      puts "STDERR: #{line}".chomp.yellow
      
      if line =~ /rtl_433 version (\S+)/
        version = Regexp.last_match(1)
        puts "Extracted version: #{version}".green
        mqtt.publish("/rtl_433/meta","version: #{version}")
      end

      if line =~ /Found (.+?) tuner/
        tuner_type = Regexp.last_match(1)
        puts "Extracted tuner type: #{tuner_type}".green
        mqtt.publish("/rtl_433/meta","tuner_type: #{tuner_type}")
      end
    end
  end
  
  thread.join

rescue Errno::EIO => e
  puts "Errno::EIO ... IO issue.".red
  puts "#{e.message}".red
rescue IOError => e
  puts "IOError ... ".red
  puts "#{e.message}".red
end
