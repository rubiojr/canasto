#
# rb_main.rb

# Created by Sergio Rubio on 5/11/09.
# Copyright Sergio Rubio <sergio@rubio.name>. All rights reserved.
#

# Loading the Cocoa framework. If you need to load more frameworks, you can
# do that here too.

begin

  framework 'Cocoa'

  $:.unshift  File.join(File.dirname(__FILE__), '../Frameworks/MacRuby.framework/Versions/Current/usr/lib/ruby/1.9.0')
  $:.unshift  File.join(File.dirname(__FILE__), '../Frameworks/MacRuby.framework/Versions/Current/usr/lib/ruby/1.9.0/universal-darwin9.0')
  $:.unshift  File.join(File.dirname(__FILE__), '../Frameworks/MacRuby.framework/Versions/Current/usr/lib/ruby/site_ruby/1.9.0/universal-darwin9.0')
  $:.unshift  File.join(File.dirname(__FILE__), 'vendor/rest-client/lib')
  $:.unshift  File.join(File.dirname(__FILE__), 'vendor/crack/lib')
  require 'logger'
  require 'restclient'
  require 'crack'

  APPLICATION_SUPPORT_DIR = File.join(ENV['HOME'], 'Library/Application Support/Canasto')
  LOG_FILE = File.join(APPLICATION_SUPPORT_DIR, 'canasto.log')

  if not Dir.exist?(APPLICATION_SUPPORT_DIR)
    Dir.mkdir APPLICATION_SUPPORT_DIR
  end

  CanastoLog = Logger.new (LOG_FILE)

  # Loading all the Ruby project files.
  dir_path = NSBundle.mainBundle.resourcePath.fileSystemRepresentation
  Dir.entries(dir_path).each do |path|
    if path != File.basename(__FILE__) and path[-3..-1] == '.rb'
      CanastoLog.debug "loading ruby file at #{path}"
      require(path)
    end
  end
  CanastoLog.debug "going main loop"
  NSApplicationMain(0, nil)
rescue Exception => e
  puts "CANASTO DEBUG: #{e.message}"
end
