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
  attr_writer :dropManagerTableView

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
        'ApiKey' => '',
        'NCXLastDropSelected' => ''
    })
    NSLog "Defaults registered"
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
		@status_bar = NSStatusBar.systemStatusBar
		@status_item = @status_bar.statusItemWithLength(NSVariableStatusItemLength)
		@status_item.setHighlightMode(true)
		@status_item.setMenu(@menu)
		
    bundle = NSBundle.mainBundle
		@app_icon = NSImage.alloc.initWithContentsOfFile(bundle.pathForResource('little_drop', :ofType => 'tiff'))
		
		@status_item.setImage(@app_icon)
    #@growl = GrowlController.new
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
      #@preferences.makeKeyAndOrderFront self
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
    puts "Deleting drop config"
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
      deleteDropConfig
    else
    end
    dc = @drops.selectedObjects.first
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
		
  def deleteDropConfig
    dc = @drops.selectedObjects.first
    error = nil
    drop = DropIO.findDropNamed dc.dropName, :withToken => dc.adminToken, :error => error
    if not drop.nil?
      drop.delete
      if DropIO.lastError == nil
        GrowlDelegate.notify 'drop.io', "Drop #{dc.dropName} destroyed!", 'DropDestroyed'
      else
        NSLog "Error deleting drop #{dc.dropName}"
        warningAlert "Error deleting drop", "Something went wrong destroying #{dc.dropName}"
      end
    else
      warningAlert "Error deleting drop", "#{dc.dropName} could not be found."
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
      plist = Plist::parse_xml(file)
      notifObj = {
        :dropName => dropName,
        :adminToken => adminToken,
        :files => plist
      }
      n = NSNotification.notificationWithName 'SendFiles', :object => notifObj
      @nQueue.enqueueNotification n, :postingStyle => NSPostWhenIdle
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
    NSLog 'Changing drop selected'
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

  def assetDownloaderFinished(notification)
    @progressIndicator.stopAnimation self
    notification.object.each do |a|
      da = DropAsset.init.alloc
      da.name = a.name
      da.type = a.type
      da.fileSize = a.filesize
      da.createdAt = a.createdAt
      @assets.addObject da
    end
  end

  def assetDownloaderError(notification)
  end

  def windowShouldClose(window)
    if window.title == 'Preferences'
      DropIO.APIKey = @userDefaults.objectForKey('ApiKey')
      NSLog "Api Key: #{DropIO.APIKey || ''}" 
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
    drop = @drops.selectedObjects.first
    NSLog "refreshing #{drop.dropName} assets"
    @assets.removeObjects @assets.content
    op = NCXAssetDownloader.alloc.init
    op.dropName = drop.dropName
    op.adminToken = drop.adminToken
    @opQueue.addOperation op
  end

  def sendFiles(notification)
    @progressIndicator.startAnimation self
    obj = notification.object
    dropName = obj['dropName']
    adminToken = obj['adminToken']
    files = obj['files']
    NSLog "Sending Files..."
    fu = NCXFileUploader.new
    fu.dropName = dropName
    fu.adminToken = adminToken
    fu.files = files
    @opQueue.addOperation fu
  end

  def fileUploaderFinished(notification)
    NSLog 'Uploader finished'
    drop = @drops.selectedObjects.first
    @progressIndicator.stopAnimation self
    NSLog 'Crearing assets'
    @assets.removeObjects(@assets.content || [])
    NSLog 'Assets Empty'
    op = NCXAssetDownloader.alloc.init
    op.dropName = drop.dropName
    op.adminToken = drop.adminToken
    @opQueue.addOperation op
  end

  def fileUploaderStarted(notification)
  end
  
  def fileUploaderSendingFile(notification)
  end

  def fileUploaderFileSent(notification)
    dropAsset = DropAsset.alloc.init
    dropAsset.name = File.basename(notification.object)
    @assets.addObject dropAsset
  end

  def createDropOperationStarted(notification)
    NSLog "Creating drop #{notification.object}"
  end

  def createDropOperationFinished(notification)
    drop = notification.object
    if drop.nil?
      NSLog "Could not create the drop!"
    else
      NSLog "Drop Created: #{drop.name} Admin Token: #{drop.adminToken}"
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

  def openWebView(sender)
    return if @drops.content.size == 0
    dropName = @drops.selectedObjects.first.dropName
    url = NSURL.URLWithString "http://drop.io/#{dropName}"
    #@browserWindow.makeKeyAndOrderFront self
    #@webView.mainFrame.loadRequest NSURLRequest.requestWithURL(url)
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

end
