#
# rb_main.rb

# Created by Sergio Rubio on 5/11/09.
# Copyright Sergio Rubio <sergio@rubio.name>. All rights reserved.
#

# Loading the Cocoa framework. If you need to load more frameworks, you can
# do that here too.
framework 'Cocoa'
framework 'JSON'
framework 'Growl'
$:.unshift  File.join(File.dirname(__FILE__), 'vendor/plist/lib')
$:.unshift  File.join(File.dirname(__FILE__), 'vendor/mime-types/lib')
$:.unshift  File.join(File.dirname(__FILE__), '../Frameworks/MacRuby.framework/Versions/Current/usr/lib/ruby/1.9.1')
$:.unshift  File.join(File.dirname(__FILE__), '../Frameworks/MacRuby.framework/Versions/Current/usr/lib/ruby/1.9.1/universal-darwin9.5')
require 'yaml'
require 'plist'

# Loading all the Ruby project files.
dir_path = NSBundle.mainBundle.resourcePath.fileSystemRepresentation
Dir.entries(dir_path).each do |path|
  if path != File.basename(__FILE__) and path[-3..-1] == '.rb'
    require(path)
  end
end

NSApplicationMain(0, nil)
