#
#  ApplicationController.rb
#  Gmail Notifr
#
#  Created by james on 10/3/08.
#  Copyright (c) 2008 ashchan.com. All rights reserved.
#

class ApplicationController < NSWindowController

  attr_writer :menu
  attr_writer :currentDropMenu

  def awakeFromNib
		@status_bar = NSStatusBar.systemStatusBar
		@status_item = @status_bar.statusItemWithLength(NSVariableStatusItemLength)
		@status_item.setHighlightMode(true)
		@status_item.setMenu(@menu)
		
    bundle = NSBundle.mainBundle
		@app_icon = NSImage.alloc.initWithContentsOfFile(bundle.pathForResource('little_drop', :ofType => 'tiff'))
		
		@status_item.setImage(@app_icon)
		@status_item.setAlternateImage(@app_alter_icon)
    @growl = GrowlController.new
    @selectedDropMenuItem = nil
    setupMenus
  end

  def setupMenus
    if IORB::Config.exist?
      IORB::DropManager.each do |details|
        mi = NSMenuItem.alloc.init
        mi.title = details.name
        mi.action = 'dropSelected:'
        mi.setTarget self
        mi.state = NSOffState
        @currentDropMenu.addItem mi
      end
    end
  end
		
  def pasteToDrop(sender)
    pb = NSPasteboard.generalPasteboard
    file = pb.stringForType NSFilenamesPboardType
    if @selectedDropMenuItem.nil?
      infoAlert("Select drop first", "Select the target drop first from 'Current Drop' menu")
    else
      if file
        plist = Plist::parse_xml(file)
        plist.each do |e|
          fname = e.strip.chomp
          if File.exist?(fname) and not File.directory?(fname)
            d = @selectedDropMenuItem.title
            details = IORB::DropManager.find(d)
            if not details.nil?
              drop = Dropio::Drop.find(details.name, details.admin_token)
              drop.add_file(fname)
              @growl.assetAdded(File.basename(e), @selectedDropMenuItem.title)
            else
              infoAlert "Drop config details not found", "Drop config is read from #{ENV[HOME]}/.iorbrc at the moment. Use iorb (http://iorb.netcorex.org) to create the drop first or add the config manually to the file."
            end
          else
            warningAlert "Could not paste file", "#{e} is not a file or something went wrong."
          end
        end
      else
        infoAlert "Nothing to paste", "Copy something to the clipboard first."
      end
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
  
  def showAbout(sender)
    NSApplication.sharedApplication.activateIgnoringOtherApps(true)
    NSApplication.sharedApplication.orderFrontStandardAboutPanel(sender)
  end

  def dropSelected(sender)
    @selectedDropMenuItem.state = NSOffState if not @selectedDropMenuItem.nil?
    sender.state = NSOnState
    @selectedDropMenuItem = sender
    @growl.dropSelected(@selectedDropMenuItem.title)
  end

end
