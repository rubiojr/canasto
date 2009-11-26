class DropController

  def init
    super
    @nQueue = NSNotificationQueue.defaultQueue
    @tQueue = Queue.new
    self
  end

  def currentDrop
    @currentDrop
  end

  def currentDrop=(dropName)
    @cd_thread = Thread.start do
      adminToken = NSUserDefaults.standardUserDefaults.dictionaryForKey('NCXDropConfigs')[dropName]
      if adminToken.nil?
        CanastoLog.error("CurrentDropController: drop config not found in changeCurrentDrop")
      end
		  n = NSNotification.notificationWithName "ChangeDropOperationStarted", :object => nil
		  @nQueue.enqueueNotification n, :postingStyle => NSPostNow
      @currentDrop = Canasto::Drop.load dropName, adminToken
      refreshAssets
		  n = NSNotification.notificationWithName "ChangeDropOperationFinished", :object => nil
		  @nQueue.enqueueNotification n, :postingStyle => NSPostNow

    end
  end


  def deleteAsset(assetName)
    @da_thread = Thread.start do 
      n = NSNotification.notificationWithName "DeleteAssetOperationStarted", :object => nil
      @nQueue.enqueueNotification n, :postingStyle => NSPostNow
      currentDrop.delete_asset(assetName)
      n = NSNotification.notificationWithName "DeleteAssetOperationFinished", :object => assetName
      @nQueue.enqueueNotification n, :postingStyle => NSPostNow
      refreshAssets
    end
  end
  
  def refreshAssets
    @ra_thread.join if @ra_thread
    @ra_thread = Thread.start do
      n = NSNotification.notificationWithName "AssetDownloaderStarted", :object => nil
      @nQueue.enqueueNotification n, :postingStyle => NSPostNow
      begin
        CanastoLog.debug 'retrieving assets...'
        assets = currentDrop.assets
        CanastoLog.debug 'assets retrieved'
        CanastoLog.debug 'Sending AssetDownloaderFinished notification'
        n =  NSNotification.notificationWithName "AssetDownloaderFinished", :object => assets	
        @nQueue.enqueueNotification n, :postingStyle => NSPostNow
      rescue Exception => e
        CanastoLog.error "refreshAssetsLoop: #{e.message}"
        n =  NSNotification.notificationWithName "AssetDownloaderError", :object => assets	
        @nQueue.enqueueNotification n, :postingStyle => NSPostNow
      end
    end
  end

  def uploadFiles(files)
    @u_thread = Thread.start do
      n = NSNotification.notificationWithName "FileUploaderStarted", :object => nil
      @nQueue.enqueueNotification n, :postingStyle => NSPostNow
      files.each do |f|
        n = NSNotification.notificationWithName "FileUploaderSendingFile", :object => f
        @nQueue.enqueueNotification n, :postingStyle => NSPostNow
        CanastoLog.debug "uploadFilesLoop sending file #{f}"
        currentDrop.upload_files([f])
        CanastoLog.debug "uploadFilesLoop file sent: #{f}"
      end
      n = NSNotification.notificationWithName "FileUploaderFinished", :object => nil
      @nQueue.enqueueNotification n, :postingStyle => NSPostNow
      refreshAssets
    end
  end

end
