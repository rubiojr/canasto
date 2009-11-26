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
  attr_accessor :preferences
  attr_accessor :apiKeyTextField
  attr_accessor :webView
  attr_accessor :browserWindow
  attr_accessor :assetsWindow
  attr_writer :dropManagerWindow
  attr_writer :assetManagerWindow
  attr_writer :dropManagerTableView
  attr_writer :searchField
  attr_writer :chatWebView
  attr_writer :progressIndicator

  def init
    super
    @opQueue = NSOperationQueue.alloc.init
    @nQueue = NSNotificationQueue.defaultQueue
    self
  end

  def awakeFromNib
    @dropController = DropController.new
    NSUserDefaultsController.sharedUserDefaultsController.setAppliesImmediately true
    @userDefaults = NSUserDefaults.standardUserDefaults
    @userDefaults.registerDefaults( { 
        'ApiKey' => '6e78ca6387783007ac739d89d57b8caa4947e56e',
        'NCXLastDropSelected' => ''
    })
    @userDefaults.synchronize
    CanastoLog.debug "Default preferences registered"
    @nc = NSNotificationCenter.defaultCenter
    @nc.addObserver self, :selector => 'fileUploaderStarted:', :name => 'FileUploaderStarted', :object => nil
    @nc.addObserver self, :selector => 'fileUploaderFinished:', :name => 'FileUploaderFinished', :object => nil
    @nc.addObserver self, :selector => 'fileUploaderFileSent:', :name => 'FileUploaderFileSent', :object => nil
    @nc.addObserver self, :selector => 'fileUploaderSendingFile:', :name => 'FileUploaderSendingFile', :object => nil
    @nc.addObserver self, :selector => 'assetDownloaderFinished:', :name => 'AssetDownloaderFinished', :object => nil
    @nc.addObserver self, :selector => 'assetDownloaderStarted:', :name => 'AssetDownloaderStarted', :object => nil
    @nc.addObserver self, :selector => 'assetDownloaderError:', :name => 'AssetDownloaderError', :object => nil
    @nc.addObserver self, :selector => 'sendFiles:', :name => 'SendFiles', :object => nil
    @nc.addObserver self, :selector => 'createDropOperationStarted:', :name => 'CreateDropOperationStarted', :object => nil
    @nc.addObserver self, :selector => 'createDropOperationFinished:', :name => 'CreateDropOperationFinished', :object => nil
    @nc.addObserver self, :selector => 'deleteAssetOperationStarted:', :name => 'DeleteAssetOperationStarted', :object => nil
    @nc.addObserver self, :selector => 'deleteAssetOperationFinished:', :name => 'DeleteAssetOperationFinished', :object => nil
    @nc.addObserver self, :selector => 'changeDropOperationStarted:', :name => 'ChangeDropOperationStarted', :object => nil
    @nc.addObserver self, :selector => 'changeDropOperationFinished:', :name => 'ChangeDropOperationFinished', :object => nil
		@status_bar = NSStatusBar.systemStatusBar
		@status_item = @status_bar.statusItemWithLength(NSVariableStatusItemLength)
		@status_item.setHighlightMode(true)
		@status_item.setMenu(@menu)
		
    bundle = NSBundle.mainBundle
		@app_icon = NSImage.alloc.initWithContentsOfFile(bundle.pathForResource('little_drop', :ofType => 'tiff'))
		
		@status_item.setImage(@app_icon)
    @selectedDropMenuItem = nil
    @progressIndicator.setUsesThreadedAnimation true
  end

  def goPremium(sender)

  end

  def dropConfigs
    @userDefaults.dictionaryForKey('NCXDropConfigs') || {}
  end

  def apiKey
    @userDefaults.objectForKey('ApiKey')
  end

  def lastDropSelected
    @userDefaults.objectForKey('NCXLastDropSelected')
  end

  def applicationDidFinishLaunching(notification)
    Growl::Notifier.sharedInstance.register 'Canasto', 
      ['ChangeDropSelected',
       'RefreshAssetsOperation',
       'DropDestroyed',
       'DropCrated',
       'AssetUploaded',
       'InvalidApiKey',
       'FilesUploaded',
       'AssetDeleted'
      ]
    if apiKey.nil? or apiKey.empty?
      NSApp.beginSheet @preferences, :modalForWindow => @assetsWindow, :modalDelegate => nil, :didEndSelector => nil, :contextInfo => nil
    else
      DropIO.APIKey = apiKey
      Canasto::Config.api_key = apiKey
      if Canasto.api_key_valid?
        CanastoLog.debug "API KEY VALID"
        loadDropConfigs
        if not dropConfigs.empty?
          changeDropSelected(currentDrop)
        end
      else
        CanastoLog.error "Invalid API Key #{apiKey}"
        Growl.growl 'InvalidApiKey', "Canasto", "Invalid API Key!!!"
      end
    end
  end

  def loadDropConfigs
    if dropConfigs.empty?
      CanastoLog.debug "No drop configs found, skipping load"
      return
    end
    dc = dropConfigs
    if dc
      lds = lastDropSelected || dc.keys.first
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
        end
        index += 1
      end
    end

  end

  def loadChat
    NSRunLoop.currentRunLoop.performSelector 'chatInLoop:', :target => self, :argument => nil, :order => 0, :modes => [NSDefaultRunLoopMode]
    #CanastoLog.debug "Loading drop chat from #{currentDrop}"
    #url = NSURL.URLWithString "http://drop.io/#{currentDrop}/remote_chat_bar.js"
    #@chatWebView.mainFrame.loadHTMLString "not implemented :(", :baseURL => url
    #CanastoLog.debug "Chat loaded for #{currentDrop}"
    #Thread.start do |t|
    #  begin
    #    html = ''
    #    dc = selectedDropConfig
    #    token = dc.adminToken
    #    drop = Canasto::Drop.load dc.dropName, dc.adminToken
    #    chat_password = drop.chat_password
    #    url = NSURL.URLWithString "http://drop.io/#{currentDrop}/remote_chat_bar.js?chat_password=#{chat_password}"
    #    html = '<html><head></head><script type="text/javascript" charset="utf-8" src="http://drop.io/' + currentDrop + '/remote_chat_bar.js?chat_password=' + chat_password + '"></script><body style="background:lightgray"><div style="color: #292929; text-align:center;font-weight:bold;font-size:72px;text-shadow: 0px 1px 1px #fff">drop.io</div><div style="font-weight: bold;font-size: 24px;text-align:center;text-shadow: 0px 1px 1px #fff;color:#292929">chat</div></body></html>'
    #    @chatWebView.mainFrame.loadHTMLString html, :baseURL => url
    #    CanastoLog.debug "Chat loaded for #{currentDrop}"
    #  rescue Exception => e
    #    CanastoLog.error "Exception loading chat:\n#{e.message}"
    #  end
    #end
  end

  def chatInLoop(id)
    CanastoLog.debug "Loading drop chat from #{currentDrop}"
    html = ''
    dc = selectedDropConfig
    token = dc.adminToken
    drop = Canasto::Drop.load dc.dropName, dc.adminToken
    chat_password = drop.chat_password
    url = NSURL.URLWithString "http://drop.io/#{currentDrop}/remote_chat_bar.js"
    html = '<html><head></head><script type="text/javascript" charset="utf-8" src="http://drop.io/' + currentDrop + '/remote_chat_bar.js?chat_password=' + chat_password + '"></script><body style="background:lightgray"><div style="color: #292929; text-align:center;font-weight:bold;font-size:72px;text-shadow: 0px 1px 1px #fff">drop.io</div><div style="font-weight: bold;font-size: 24px;text-align:center;text-shadow: 0px 1px 1px #fff;color:#292929">chat</div></body></html>'
    @chatWebView.mainFrame.loadHTMLString html, :baseURL => url
    CanastoLog.debug "Chat loaded for #{currentDrop}"
  end

  def preferencesClosed(sender)
    @userDefaults.synchronize
    DropIO.APIKey = apiKey
    Canasto::Config.api_key = apiKey
    NSApp.endSheet @preferences
    @preferences.orderOut sender
  end

  def deleteDropConfigAlert(sender)
    alert = NSAlert.new
    alert.addButtonWithTitle "Cancel"
    alert.addButtonWithTitle "OK"
    alert.setMessageText "Do you want to destroy the drop #{selectedDropConfig.dropName}?"
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
    dc = selectedDropConfig
    CanastoLog.debug "Removing config for drop #{dc.dropName}"
    @drops.removeObject dc
    configs = {}.merge(@userDefaults.dictionaryForKey('NCXDropConfigs') || {})
    configs.delete dc.dropName
    @userDefaults.setObject configs, :forKey => 'NCXDropConfigs'
    @userDefaults.synchronize
    @assets.removeObjects @assets.content
    if @drops.content and @drops.content.size > 0
      changeDropSelected selectedDropConfig.dropName
    end
  end

  def deleteRemoteDrop
    dc = selectedDropConfig
    error = nil
    drop = DropIO.findDropNamed dc.dropName, :withToken => dc.adminToken, :error => error
    if not drop.nil?
      drop.delete
      if DropIO.lastError == nil
        CanastoLog.debug "Deleted drop #{dc.dropName} from drop.io"
        Growl.growl 'DropDestroyed', "Canasto", "Drop #{dc.dropName} destroyed!"
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
    dc = selectedDropConfig
    obj = @assets.selectedObjects.first
    if returnCode == NSAlertSecondButtonReturn
      CanastoLog.debug "User wants to delete the asset, let's go"
      begin
        @dropController.deleteAsset(obj.name)
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
        if k == selectedDropConfig.dropName
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
      uploadFiles(pfiles)
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

  def changeDropOperationStarted(notification)
    CanastoLog.debug 'ChangeDropOperationStarted'
  end

  def changeDropOperationFinished(notification)
    CanastoLog.debug 'ChangeDropOperationFinished'
    index = 0
    @drops.arrangedObjects.each do |config|
      if config.dropName == dropName
        @drops.setSelectionIndex index 
        CanastoLog.debug "Selected index set for Drops array controller"
      end
      index += 1
    end
    @userDefaults.setObject dropName, :forKey => 'NCXLastDropSelected'
    @pasteMenuItem.enabled = true
    @pasteMenuItem.title = "Paste to #{dropName}"
    #dropConfig = nil
    #@drops.arrangedObjects.each do |dc|
    #  if dc.dropName == dropName
    #    CanastoLog.debug "Drop config found for drop #{dropName}"
    #    dropConfig = dc 
    #  end
    #end
    #if dropConfig.nil?
    #    CanastoLog.error "FATAL Drop config NOT FOUND for drop #{dropName}"
    #end
  end

  def changeDropSelected(dropName)
    @progressIndicator.startAnimation self
    CanastoLog.debug "Changing drop selected from #{lastDropSelected} to #{dropName}"
    @dropController.currentDrop = dropName
    #loadChat
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
      changeDropSelected selectedDropConfig.dropName
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
      if dc.dropName == selectedDropConfig.dropName
        mi.state = NSOnState
      else
        mi.state = NSOffState
      end
      menu.addItem mi
    end
  end

  def assetManagerPopupButtonClicked(sender)
    changeDropSelected(selectedDropConfig.dropName)
  end

  def selectedDropConfig
    @drops.selectedObjects.first
  end

  def assetDownloaderStarted(notification)
  end

  # Triggered when search field content changes
  def updateFilter(sender)
    CanastoLog.debug @searchField.stringValue
  end

  def assetDownloaderFinished(notification)
    @assets.removeObjects @assets.content
    notification.object.each do |a|
      da = DropAsset.new
      da.name = a.name
      da.title = a.title
      da.type = a.type
      da.URL = a.hidden_url
      da.fileSize = a.filesize
      da.createdAt = a.created_at
      @assets.addObject da
    end
    @progressIndicator.stopAnimation self
  end

  def assetDownloaderError(notification)
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
  end

  def windowShouldClose(window)
    if window.title == 'Preferences'
      DropIO.APIKey = @userDefaults.objectForKey('ApiKey')
      Canasto::Config.api_key = @userDefaults.objectForKey('ApiKey')
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
    @dropController.refreshAssets
  end

  def sendFiles(notification)
    obj = notification.object
    uploadFiles(obj)
  end

  def uploadFiles(obj)
    files = obj[:files]
    CanastoLog.debug "File list:"
    CanastoLog.debug "\n#{files.join("\n")}"
    @dropController.uploadFiles(files)
  end
  
  def openWebView(sender)
    return if @drops.content.size == 0
    dropName = selectedDropConfig.dropName
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
    @progressIndicator.stopAnimation self
    drop = selectedDropConfig
    CanastoLog.debug "FileUploadOperationFinished. drop: #{drop.dropName}"
    Growl.growl 'FilesUploaded', 'Canasto', "Files uploaded!"
  end

  def fileUploaderStarted(notification)
    @progressIndicator.startAnimation self
    Growl.growl 'AssetUploaded', 'Canasto', "Uploading files to #{currentDrop}"
  end
  
  def fileUploaderSendingFile(notification)
    CanastoLog.debug "Sending file #{notification.object}"
  end

  def fileUploaderFileSent(notification)
    Growl.growl "AssetUploaded", 'Canasto', "File #{notification.object} uploaded!"
  end

  def deleteAssetOperationFinished(notification)
    Growl.growl 'AssetDeleted', 'Canasto', "Asset #{notification.object} deleted!"
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
      Growl.growl 'DropCreated', 'Canasto', "Error creating the drop #{drop.name}"
    else
      CanastoLog.debug "Drop Created: #{drop.name}"
      dc = {}.merge(@userDefaults.dictionaryForKey('NCXDropConfigs') || {})
      dc[drop.name] = drop.adminToken
      CanastoLog.debug 'Adding drop config to NCXDropConfigs'
      @userDefaults.setObject dc, :forKey => 'NCXDropConfigs'
      @userDefaults.synchronize
      CanastoLog.debug 'Drop config added to NCXDropConfigs'
      CanastoLog.debug 'Adding drop to Drops Array Controller'
      config = DropConfig.new
      config.dropName = drop.name
      config.adminToken = drop.adminToken
      @drops.addObject config
      CanastoLog.debug 'Drop added to Drops Array Controller'
      changeDropSelected drop.name
      Growl.growl "DropCreated", "Canasto", "Drop #{drop.name} created"
    end
  end

end
