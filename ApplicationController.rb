#
#  ApplicationController.rb
#  Gmail Notifr
#
#  Created by james on 10/3/08.
#  Copyright (c) 2008 ashchan.com. All rights reserved.
#

class ApplicationController 

  attr_writer :menu
  attr_writer :pasteMenuItem
  attr_accessor :assetManagerDropSelector
  # Drops Array Controller
  attr_writer :drops, :assets
  # Assets Array Controller
  attr_writer :progressIndicator
  attr_accessor :preferences
  attr_accessor :apiKeyTextField
  attr_accessor :webView
  attr_accessor :browserWindow
  attr_accessor :assetsWindow
  attr_writer :dropManagerWindow
  attr_writer :assetManagerWindow
  attr_writer :dropManagerTableView
  attr_writer :searchField

  def init
    super
    @opQueue = NSOperationQueue.alloc.init
    @nQueue = NSNotificationQueue.defaultQueue
    self
  end

  def awakeFromNib
    GrowlApplicationBridge.setGrowlDelegate GrowlDelegate.new

    NSUserDefaultsController.sharedUserDefaultsController.setAppliesImmediately true
    @userDefaults = NSUserDefaults.standardUserDefaults
    @userDefaults.registerDefaults( { 
        'ApiKey' => '6e78ca6387783007ac739d89d57b8caa4947e56e',
        'NCXLastDropSelected' => ''
    })
    CanastoLog.debug "Default preferences registered"
    @nc = NSNotificationCenter.defaultCenter
    @nc.addObserver self, :selector => 'fileUploaderStarted:', :name => 'FileUploaderStarted', :object => nil
    @nc.addObserver self, :selector => 'fileUploaderFinished:', :name => 'FileUploaderFinished', :object => nil
    @nc.addObserver self, :selector => 'fileUploaderFileSent:', :name => 'FileUploaderFileSent', :object => nil
    @nc.addObserver self, :selector => 'fileUploaderSendingFile:', :name => 'FileUploaderSendingFile', :object => nil
    @nc.addObserver self, :selector => 'assetDownloaderFinished:', :name => 'AssetDownloaderFinished', :object => nil
    @nc.addObserver self, :selector => 'assetDownloaderStarted:', :name => 'AssetDownloaderStarted', :object => nil
    @nc.addObserver self, :selector => 'assetDownloaderError:', :name => 'AssetDownloaderError', :object => nil
    @nc.addObserver self, :selector => 'refreshAssets:', :name => 'DropIORefreshAssets', :object => nil
    @nc.addObserver self, :selector => 'sendFiles:', :name => 'SendFiles', :object => nil
    @nc.addObserver self, :selector => 'createDropOperationStarted:', :name => 'CreateDropOperationStarted', :object => nil
    @nc.addObserver self, :selector => 'createDropOperationFinished:', :name => 'CreateDropOperationFinished', :object => nil
    @nc.addObserver self, :selector => 'deleteAssetOperationStarted:', :name => 'DeleteAssetOperationStarted', :object => nil
    @nc.addObserver self, :selector => 'deleteAssetOperationFinished:', :name => 'DeleteAssetOperationFinished', :object => nil
		@status_bar = NSStatusBar.systemStatusBar
		@status_item = @status_bar.statusItemWithLength(NSVariableStatusItemLength)
		@status_item.setHighlightMode(true)
		@status_item.setMenu(@menu)
		
    bundle = NSBundle.mainBundle
		@app_icon = NSImage.alloc.initWithContentsOfFile(bundle.pathForResource('little_drop', :ofType => 'tiff'))
		
		@status_item.setImage(@app_icon)
    @selectedDropMenuItem = nil
  end

  def applicationDidFinishLaunching(notification)
    dc = @userDefaults.dictionaryForKey('NCXDropConfigs')
    apiKey = @userDefaults.objectForKey('ApiKey')
    DropIO.APIKey = apiKey
    if dc
      lds = @userDefaults.objectForKey('NCXLastDropSelected') || dc.keys.first
      dc.each do |k,v| 
        config = DropConfig.new
        config.dropName = k
        config.adminToken = v
        @drops.addObject config
      end
      index = 0
      dc.each do |k, v|
        if k == lds
          @drops.setSelectionIndex index
          @pasteMenuItem.enabled = true
          @pasteMenuItem.title = "Paste to #{lds}"
          dropConfig = DropConfig.new
          dropConfig.dropName = k
          dropConfig.adminToken = v
          n = NSNotification.notificationWithName 'DropIORefreshAssets', :object => dropConfig
          @nQueue.enqueueNotification n, :postingStyle => NSPostWhenIdle
        end
        index += 1
      end
    end
    if @userDefaults.objectForKey('ApiKey').empty?
      NSApp.beginSheet @preferences, :modalForWindow => @assetsWindow, :modalDelegate => nil, :didEndSelector => nil, :contextInfo => nil
    end
  end

  def preferencesClosed(sender)
    @userDefaults.synchronize
    DropIO.APIKey = @userDefaults.objectForKey('ApiKey')
    NSApp.endSheet @preferences
    @preferences.orderOut sender
  end

  def deleteDropConfigAlert(sender)
    alert = NSAlert.new
    alert.addButtonWithTitle "Cancel"
    alert.addButtonWithTitle "OK"
    alert.setMessageText "Do you want to destroy the drop #{@drops.selectedObjects.first.dropName}?"
    alert.setInformativeText "WARNING: Destroyed drops cannot be restored"
    alert.setAlertStyle NSWarningAlertStyle
    alert.beginSheetModalForWindow @dropManagerWindow, :modalDelegate => self, :didEndSelector => 'deleteDropConfigAlertDidEnd:returnCode:contextInfo:', :contextInfo => nil
  end

  def deleteDropConfigAlertDidEnd(alert, returnCode:returnCode, contextInfo:contextInfo)
    if returnCode == NSAlertSecondButtonReturn
      deleteRemoteDrop
    else
    end
    deleteDropConfig
  end

  def deleteDropConfig
    dc = @drops.selectedObjects.first
    CanastoLog.debug "Removing config for drop #{dc.dropName}"
    @drops.removeObject dc
    configs = {}.merge(@userDefaults.dictionaryForKey('NCXDropConfigs') || {})
    configs.delete dc.dropName
    @userDefaults.setObject configs, :forKey => 'NCXDropConfigs'
    @userDefaults.synchronize
    if @drops.content and @drops.content.size == 0
      @assets.removeObjects @assets.content
    elsif @drops.content and @drops.content.size > 0
      changeDropSelected @drops.selectedObjects.first.dropName
    end
  end

  def deleteRemoteDrop
    dc = @drops.selectedObjects.first
    error = nil
    drop = DropIO.findDropNamed dc.dropName, :withToken => dc.adminToken, :error => error
    if not drop.nil?
      drop.delete
      if DropIO.lastError == nil
        CanastoLog.debug "Deleted drop #{dc.dropName} from drop.io"
        GrowlDelegate.notify 'drop.io', "Drop #{dc.dropName} destroyed!", 'DropDestroyed'
      else
        CanastoLog.debug "Error deleting drop #{dc.dropName}"
        warningAlert "Error deleting drop", "Something went wrong destroying #{dc.dropName}"
      end
    else
      CanastoLog.debug "Could not delete drop #{dc.dropName} from drop.io: Not Found"
      warningAlert "Error deleting drop", "#{dc.dropName} could not be found."
    end
  end

  def deleteAssetFromDropAlert(sender)
    asset_name = @assets.selectedObjects.first.name
    CanastoLog.debug "Asking to delete asset #{asset_name}"
    alert = NSAlert.new
    alert.addButtonWithTitle "Cancel"
    alert.addButtonWithTitle "OK"
    alert.setMessageText "Do you want to delete the asset #{asset_name}?"
    alert.setInformativeText "WARNING: Deleted assets cannot be restored"
    alert.setAlertStyle NSWarningAlertStyle
    alert.beginSheetModalForWindow @assetManagerWindow, :modalDelegate => self, :didEndSelector => 'deleteAssetFromDropAlertDidEnd:returnCode:contextInfo:', :contextInfo => nil
  end
  
  def deleteAssetFromDropAlertDidEnd(alert, returnCode:returnCode, contextInfo:contextInfo) 
    dc = @drops.selectedObjects.first
    obj = @assets.selectedObjects.first
    if returnCode == NSAlertSecondButtonReturn
      CanastoLog.debug "User wants to delete the asset, let's go"
      @progressIndicator.startAnimation self
      begin
        properties = {
          'dropName' => dc.dropName,
          'adminToken' => dc.adminToken,
          'assetName' => obj.name
        }
        op = DeleteAssetOperation.alloc.init
        op.properties = properties
        CanastoLog.debug "Queing DeleteAssetOperation for asset #{obj.name}"
        @opQueue.addOperation op
      rescue Exception => e
        CanastoLog.debug "Exception deleting asset #{obj.name}: #{e.message}"
      end
    else
      CanastoLog.debug "User cancelled asset deletion for #{obj.name}"
    end
  end

  def pasteToDrop(sender)
    pb = NSPasteboard.generalPasteboard
    file = pb.stringForType NSFilenamesPboardType
    if file
      dc = @userDefaults.dictionaryForKey('NCXDropConfigs')
      dropName = nil
      adminToken = nil
      dc.each do |k,v|
        if k == @drops.selectedObjects.first.dropName
          dropName = k
          adminToken = v
        end
      end
      pfiles = []
      file.each_line do |l|
        if l =~ /<string>(.*)<\/string>/
          pfiles << $1
        end
      end
      CanastoLog.debug "Pasting files to drop"
      notifObj = {
        :dropName => dropName,
        :adminToken => adminToken,
        :files => pfiles
      }
      uploadFiles(notifObj)
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
    @selectedDropMenuItem = sender
    dropName = @selectedDropMenuItem.title
    changeDropSelected(dropName)
  end

  def changeDropSelected(dropName)
    last_drop_selected = @userDefaults.objectForKey('NCXLastDropSelected')
    CanastoLog.debug "Changing drop selected from #{last_drop_selected} to #{dropName}"
    @progressIndicator.startAnimation self
    index = 0
    @drops.arrangedObjects.each do |config|
      @drops.setSelectionIndex index if config.dropName == dropName
      index += 1
    end
    @userDefaults.setObject dropName, :forKey => 'NCXLastDropSelected'
    @pasteMenuItem.enabled = true
    @pasteMenuItem.title = "Paste to #{dropName}"
    dropConfig = nil
    @drops.arrangedObjects.each do |dc|
      dropConfig = dc if dc.dropName == dropName
    end
    GrowlDelegate.notify 'Canasto', "Changed current drop to #{dropName}", "ChangedDropSelected"
    n = NSNotification.notificationWithName 'DropIORefreshAssets', :object => dropConfig
    @nQueue.enqueueNotification n, :postingStyle => NSPostNow
  end

  def saveDropConfigs(sender)
    drops = @drops.arrangedObjects
    dc = {}
    drops.each do |d|
      dc[d.dropName] = d.adminToken
    end
    @userDefaults.setObject dc, :forKey => 'NCXDropConfigs'
    @userDefaults.synchronize
    if @drops.content.size > 0
      changeDropSelected @drops.selectedObjects.first.dropName
    end
    @dropManagerWindow.performClose self
  end

  def menuNeedsUpdate(menu)
    menu.itemArray.each do |i|
      menu.removeItem i
    end
    @drops.arrangedObjects.each do |dc| 
      mi = NSMenuItem.new
      mi.title = dc.dropName
      mi.action = 'dropSelected:'
      mi.setTarget self
      if dc.dropName == @drops.selectedObjects.first.dropName
        mi.state = NSOnState
      else
        mi.state = NSOffState
      end
      menu.addItem mi
    end
  end

  def assetManagerPopupButtonClicked(sender)
    changeDropSelected(@drops.selectedObjects.first.dropName)
  end


  def assetDownloaderStarted(notification)
  end

  # Triggered when search field content changes
  def updateFilter(sender)
    CanastoLog.debug @searchField.stringValue
  end

  def assetDownloaderFinished(notification)
    @progressIndicator.stopAnimation self
    notification.object.each do |a|
      da = DropAsset.new
      da.name = a.name
      da.title = a.title
      da.type = a.type
      da.URL = a.hiddenUrl
      da.fileSize = a.filesize
      da.createdAt = a.createdAt
      @assets.addObject da
    end
  end

  def assetDownloaderError(notification)
    @progressIndicator.stopAnimation self
    alert = NSAlert.new
    alert.informativeText = 'The selected drop no longer exists. Do you want to remove it from the list?'
    alert.messageText = 'Invalid Drop'
    alert.alertStyle = NSWarningAlertStyle
    alert.addButtonWithTitle("Cancel")
    alert.addButtonWithTitle("OK")
    response = alert.runModal
    if response == NSAlertSecondButtonReturn
      deleteDropConfig
    end
    #GrowlDelegate.notify 'drop.io', "Drop #{dc.dropName} does not exist", 'DropDestroyed'
  end

  def windowShouldClose(window)
    if window.title == 'Preferences'
      DropIO.APIKey = @userDefaults.objectForKey('ApiKey')
      CanastoLog.debug "Api Key: #{DropIO.APIKey || ''}" 
      @userDefaults.setObject @apiKeyTextField.stringValue, :forKey => 'ApiKey'
      @userDefaults.synchronize
    end
    if not DropIO.checkAPIKey
      warningAlert('Invalid API Key', 'The api key is not valid, double check it') 
      return false
    end
    true
  end

  def refreshAssets(notification)
    @progressIndicator.startAnimation self
    drop = @drops.selectedObjects.first
    CanastoLog.debug "refreshing #{drop.dropName} assets"
    @assets.removeObjects @assets.content
    op = AssetDownloadOperation.new
    op.dropName = drop.dropName
    op.adminToken = drop.adminToken
    @opQueue.addOperation op
  end

  def sendFiles(notification)
    @progressIndicator.startAnimation self
    obj = notification.object
    uploadFiles(obj)
  end

  def uploadFiles(obj)
    dropName = obj[:dropName]
    adminToken = obj[:adminToken]
    files = obj[:files]
    CanastoLog.debug "Sending files to drop #{dropName}"
    CanastoLog.debug "File list:"
    CanastoLog.debug "\n#{files.join("\n")}"
    fu = FileUploadOperation.new
    fu.dropName = dropName
    fu.adminToken = adminToken
    fu.files = files
    CanastoLog.debug "Queing FileUploadOperation for drop #{dropName}"
    @opQueue.addOperation fu
  end
  
  def openWebView(sender)
    return if @drops.content.size == 0
    dropName = @drops.selectedObjects.first.dropName
    url = NSURL.URLWithString "http://drop.io/#{dropName}"
    NSWorkspace.sharedWorkspace.openURL url
  end

  def addDropFromConfig(sender)
    window = sender.window
    editingEnded = window.makeFirstResponder window
    dc = DropConfig.new
    @drops.addObject dc
    row = @drops.arrangedObjects.indexOfObjectIdenticalTo dc
    @dropManagerTableView.editColumn 0, 
                          :row => row,
                          :withEvent => nil,
                          :select => true 
  end

  def currentDrop
    @userDefaults.objectForKey('NCXLastDropSelected') || '' 
  end

  #
  # NSOperation Handlers
  #
  def fileUploaderFinished(notification)
    drop = @drops.selectedObjects.first
    CanastoLog.debug "FileUploadOperation finished. drop: #{drop.dropName}"
    @progressIndicator.stopAnimation self
    CanastoLog.debug "Clearing assets to display assets from drop #{drop.dropName}"
    @assets.removeObjects(@assets.content || [])
    op = AssetDownloadOperation.new
    op.dropName = drop.dropName
    op.adminToken = drop.adminToken
    CanastoLog.debug "Refresing assets from drop #{drop.dropName}"
    @opQueue.addOperation op
  end

  def fileUploaderStarted(notification)
    GrowlDelegate.notify 'Canasto', "Uploading files to #{currentDrop}", "AssetUploaded"
  end
  
  def fileUploaderSendingFile(notification)
    CanastoLog.debug "Sending file #{notification.object}"
  end

  def fileUploaderFileSent(notification)
    dropAsset = DropAsset.alloc.init
    dropAsset.name = File.basename(notification.object)
    GrowlDelegate.notify 'Canasto', "File #{notification.object} uploaded!", "AssetUploaded"
    @assets.addObject dropAsset
  end

  def deleteAssetOperationFinished(notification)
    @progressIndicator.stopAnimation self
    obj = @assets.selectedObjects.first
    @assets.removeObject obj
    GrowlDelegate.notify 'Canasto', "Asset #{notification.object} deleted!", "AssetDeleted"
    CanastoLog.debug "DeleteAssetOperation finished for #{notification.object}"
  end

  def deleteAssetOperationStarted(notification)
    CanastoLog.debug "DeleteAssetOperation started for #{notification.object}"
  end

  def createDropOperationStarted(notification)
    CanastoLog.debug "Creating drop #{notification.object}"
  end

  def createDropOperationFinished(notification)
    drop = notification.object
    if drop.nil?
      CanastoLog.debug "Could not create the drop #{drop.name}"
      GrowlDelegate.notify 'Canasto', "Error creating the drop #{drop.name}", "DropCreated"
    else
      CanastoLog.debug "Drop Created: #{drop.name}"
      dc = {}.merge(@userDefaults.dictionaryForKey('NCXDropConfigs') || {})
      dc[drop.name] = drop.adminToken
      @userDefaults.setObject dc, :forKey => 'NCXDropConfigs'
      @userDefaults.synchronize
      config = DropConfig.alloc.init
      config.dropName = drop.name
      config.adminToken = drop.adminToken
      @drops.addObject config
      changeDropSelected drop.name
      GrowlDelegate.notify 'drop.io', "Drop #{drop.name} created", "DropCreated"
    end
  end

end
