#
# rb_main.rb

# Created by Sergio Rubio on 5/11/09.
# Copyright Sergio Rubio <sergio@rubio.name>. All rights reserved.
#

# Loading the Cocoa framework. If you need to load more frameworks, you can
# do that here too.
framework 'Cocoa'
framework 'Growl'
$:.unshift  File.join(File.dirname(__FILE__), '../Frameworks/MacRuby.framework/Versions/Current/usr/lib/ruby/1.9.0')
$:.unshift  File.join(File.dirname(__FILE__), '../Frameworks/MacRuby.framework/Versions/Current/usr/lib/ruby/1.9.0/universal-darwin9.0')
$:.unshift  File.join(File.dirname(__FILE__), '../Frameworks/MacRuby.framework/Versions/Current/usr/lib/ruby/site_ruby/1.9.0/universal-darwin9.0')
$:.unshift  File.join(File.dirname(__FILE__), 'vendor/rest-client/lib')
$:.unshift  File.join(File.dirname(__FILE__), 'vendor/crack/lib')
require 'logger'
require 'restclient'
require 'crack'

module Canasto
  APPLICATION_SUPPORT_DIR = File.join(
    NSSearchPathForDirectoriesInDomains(
      NSApplicationSupportDirectory, NSUserDomainMask, true),
    'Canasto'
  )

  LOG_FILE = File.join(APPLICATION_SUPPORT_DIR, 'canasto.log')

end
if not Dir.exist?(Canasto::APPLICATION_SUPPORT_DIR)
  Dir.mkdir Canasto::APPLICATION_SUPPORT_DIR
end
CanastoLog = Logger.new (Canasto::LOG_FILE)

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
