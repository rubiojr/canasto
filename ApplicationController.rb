#
#  ApplicationController.rb
#  Gmail Notifr
#
#  Created by james on 10/3/08.
#  Copyright (c) 2008 ashchan.com. All rights reserved.
#

class ApplicationController 

  attr_writer :menu
  attr_writer :currentDropMenu
  attr_writer :tableView
  attr_accessor :document
  attr_writer :pasteMenuItem
  attr_accessor :assetManagerDropSelector

  def awakeFromNib
		@status_bar = NSStatusBar.systemStatusBar
		@status_item = @status_bar.statusItemWithLength(NSVariableStatusItemLength)
		@status_item.setHighlightMode(true)
		@status_item.setMenu(@menu)
		
    bundle = NSBundle.mainBundle
		@app_icon = NSImage.alloc.initWithContentsOfFile(bundle.pathForResource('little_drop', :ofType => 'tiff'))
		
		@status_item.setImage(@app_icon)
		#@status_item.setAlternateImage(@app_alter_icon)
    @growl = GrowlController.new
    @selectedDropMenuItem = nil
    setupMenus
  end

  def setupMenus
    document.dropConfigs.each do |c|
    #if IORB::Config.exist?
    #  IORB::DropManager.each do |details|
      mi = NSMenuItem.alloc.init
      mi.title = c.dropName
      mi.action = 'dropSelected:'
      mi.setTarget self
      mi.state = NSOffState
      @currentDropMenu.addItem mi
    end
    #  end
    #end
  end
		
  def pasteToDrop(sender)
    pb = NSPasteboard.generalPasteboard
    file = pb.stringForType NSFilenamesPboardType
    if file
      dropName = @selectedDropMenuItem.title
      details = @document.dropConfigs.find { |dc| dc.dropName == dropName }
      begin
        drop = Dropio::Drop.find(details.dropName, details.adminToken)
        plist = Plist::parse_xml(file)
        plist.each do |e|
          fname = e.strip.chomp
          if File.exist?(fname) and not File.directory?(fname)
            drop.add_file(fname)
            @growl.assetAdded(File.basename(e), @selectedDropMenuItem.title)
          else
            warningAlert "Could not paste file", "#{e} is not a file or something went wrong."
          end
        end
      rescue Exception => e
        warningAlert "Unknown Error", "#{e.message}"
      end
    else
      infoAlert "Nothing to paste", "Copy something to the clipboard first."
    end
  end
  
  def warningAlert(msg, desc)
    alert = NSAlert.alloc.init
    alert.informativeText = desc
    alert.messageText = msg
    alert.alertStyle = NSWarningAlertStyle
    alert.addButtonWithTitle("OK")
    alert.runModal
  end
  
  def infoAlert(msg, desc)
    alert = NSAlert.alloc.init
    alert.informativeText = desc
    alert.messageText = msg
    alert.alertStyle = NSInformationalAlertStyle
    alert.addButtonWithTitle("OK")
    alert.runModal
  end
  
  def dropSelected(sender)
    @selectedDropMenuItem.state = NSOffState if not @selectedDropMenuItem.nil?
    sender.state = NSOnState
    @selectedDropMenuItem = sender
    @growl.dropSelected(@selectedDropMenuItem.title)
    @pasteMenuItem.enabled = true
    @assetManagerDropSelector.enabled = true
    @pasteMenuItem.title = "Paste to #{@selectedDropMenuItem.title}"
  end

end
