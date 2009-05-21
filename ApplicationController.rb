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
  attr_writer :assetManagerDropsTableView
  attr_writer :pasteMenuItem
  attr_accessor :assetManagerDropSelector
  attr_writer :drops
  attr_writer :assets
  attr_writer :progressIndicator

  def awakeFromNib
    @animate = false
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
    @userDefaults = NSUserDefaults.standardUserDefaults
  end

  def applicationDidFinishLaunching(notification)
    dc = @userDefaults.dictionaryForKey('NCXDropConfigs')
    if dc
      dc.each do |k,v| 
        dc = DropConfig.new
        dc.dropName = k
        dc.adminToken = v
        @drops.addObject dc
      end
    end
    populateDropsMenu
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
  
  def tableView(tv, shouldSelectRow:tableRow)
    dc = @drops.arrangedObjects[tableRow]
    changeDropSelected(dc.dropName)
    true
  end

  def dropSelected(sender)
    @selectedDropMenuItem = sender
    dropName = @selectedDropMenuItem.title
    changeDropSelected(dropName)
  end

  def changeDropSelected(dropName)
    @progressIndicator.startAnimation(self)
    index = 0
    @currentDropMenu.itemArray.each do |i|
      if i.title == dropName
        i.state = NSOnState
        is = NSIndexSet.indexSetWithIndex index
        @assetManagerDropsTableView.selectRowIndexes is,:byExtendingSelection => false
      else
        i.state = NSOffState
      end
      index += 1
    end
    @growl.dropSelected(dropName)
    @userDefaults.setObject dropName, :forKey => 'NCXLastDropSelected'
    @pasteMenuItem.enabled = true
    @pasteMenuItem.title = "Paste to #{dropName}"
    adminToken = nil
    @drops.arrangedObjects.each do |dc|
      adminToken = dc.adminToken if dc.dropName == dropName
    end
    Thread.start do 
      drop = Dropio::Drop.find(dropName, adminToken)
      @assets.removeObjects @assets.arrangedObjects
      drop.assets.each do |a|
        da = DropAsset.new
        da.name = a.name
        da.type = a.type
        da.fileSize = a.filesize
        da.createdAt = a.created_at
        @assets.addObject da
      end
      @progressIndicator.stopAnimation self
    end
  end

  def saveDropConfigs(sender)
    drops = @drops.arrangedObjects
    dc = {}
    drops.each do |d|
      dc[d.dropName] = d.adminToken
    end
    @userDefaults.setObject dc, :forKey => 'NCXDropConfigs'
    @currentDropMenu.itemArray.each do |i|
      @currentDropMenu.removeItem i
    end
    populateDropsMenu
  end

  def populateDropsMenu
    lds = @userDefaults.objectForKey('NCXLastDropSelected') || dc.keys.first
    @drops.arrangedObjects.each do |dc| 
      mi = NSMenuItem.new
      mi.title = dc.dropName
      mi.action = 'dropSelected:'
      mi.setTarget self
      if lds == dc.dropName
        mi.state = NSOnState
        changeDropSelected(lds)
      else
        mi.state = NSOffState
      end
      @currentDropMenu.addItem mi
    end
  end

end
