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

  def init
    super
    @opQueue = NSOperationQueue.alloc.init
    @nQueue = NSNotificationQueue.defaultQueue
    self
  end

  def awakeFromNib
    @userDefaults = NSUserDefaults.standardUserDefaults
    @userDefaults.registerDefaults( { 
        'ApiKey' => '',
        'NCXLastDropSelected' => ''
    })
    NSLog "Defaults registered"
    @nc = NSNotificationCenter.defaultCenter
    @nc.addObserver self, :selector => 'fileSent:', :name => 'FileUploaderFileSent', :object => nil
    @nc.addObserver self, :selector => 'sendingFile:', :name => 'FileUploaderSendingFile', :object => nil
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
    @growl = GrowlController.new
    @selectedDropMenuItem = nil
  end

  def applicationDidFinishLaunching(notification)
    dc = @userDefaults.dictionaryForKey('NCXDropConfigs')
    apiKey = @userDefaults.objectForKey('ApiKey')
    Dropio.api_key = apiKey
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
      @preferences.makeKeyAndOrderFront self
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
    @nQueue.enqueueNotification n, :postingStyle => NSPostWhenIdle
  end

  def saveDropConfigs(sender)
    drops = @drops.arrangedObjects
    dc = {}
    drops.each do |d|
      dc[d.dropName] = d.adminToken
    end
    @userDefaults.setObject dc, :forKey => 'NCXDropConfigs'
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

  def sendingFile(notification)
  end

  def fileSent(notification)
    @progressIndicator.stopAnimation self
    NSLog 'asset uploaded'
    dropConfig = nil
    @drops.arrangedObjects.each do |dc|
      dropConfig = dc if dc.dropName == @userDefaults.objectForKey('NCXLastDropSelected')
    end
    n = NSNotification.notificationWithName 'DropIORefreshAssets', :object => dropConfig
    @nQueue.enqueueNotification n, :postingStyle => NSPostNow
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
    end
    if not DropIO.checkAPIKey
      warningAlert('Invalid API Key', 'The api key is not valid, double check it') 
      return false
    end
    true
  end

  def windowDidBecomeKey(notification)
    window = notification.object
    if window.title == 'Drop Manager'
      if @drops.arrangedObjects.nil? or @drops.arrangedObjects.empty?
      else
        @drops.removeObjects(@drops.arrangedObjects || [])
      end
      dc = @userDefaults.dictionaryForKey('NCXDropConfigs') || {}
      dc.each do |k,v| 
        config = DropConfig.new
        config.dropName = k
        config.adminToken = v
        @drops.addObject config
      end
    elsif window.title == 'Asset Manager'
      dc = @userDefaults.dictionaryForKey('NCXDropConfigs') || {}
      @drops.removeObjects (@drops.arrangedObjects || [])
      dc.each do |k,v| 
        config = DropConfig.new
        config.dropName = k
        config.adminToken = v
        @drops.addObject config
      end
    else
    end
  end
  
  def refreshAssets(notification)
    NSLog "refreshing #{notification.object.dropName} assets"
    @assets.removeObjects @assets.arrangedObjects
    op = NCXAssetDownloader.alloc.init
    op.dropName = notification.object.dropName
    op.adminToken = notification.object.adminToken
    @opQueue.addOperation op
  end

  def createDrop(notification)
    properties = notification.object
    NSLog "Creating drop #{properties['dropName']}"
    op = CreateDropOperation.alloc.init
    op.properties = properties
    @opQueue.addOperation op
  end
  
  def sendFiles(notification)
    @progressIndicator.startAnimation self
    obj = notification.object
    begin
      dropName = obj['dropName']
      adminToken = obj['adminToken']
      files = obj['files']
      obj['files'].each do |e|
        drop = Dropio::Drop.find(dropName, adminToken)
        fname = e.strip.chomp
        if File.exist?(fname) and not File.directory?(fname)
          fu = NCXFileUploader.new
          fu.dropName = dropName
          fu.adminToken = adminToken
          fu.file = fname
          @opQueue.addOperation fu
        else
          puts 'File does not exist'
        end
      end
    rescue Exception => e
      puts "CRITICAL: #{e.message}"
    end
  end

  def createDropOperationStarted(notification)
    NSLog "Creating drop #{notification.object}"
  end

  def createDropOperationFinished(notification)
    drop = notification.object
    NSLog "Drop Created: #{drop.name} Admin Token: #{drop.adminToken}"
    dc = {}.merge(@userDefaults.dictionaryForKey('NCXDropConfigs') || {})
    dc[drop.name] = drop.adminToken
    @userDefaults.setObject dc, :forKey => 'NCXDropConfigs'
    config = DropConfig.alloc.init
    config.dropName = drop.name
    config.adminToken = drop.adminToken
    @drops.addObject config
  end

end
