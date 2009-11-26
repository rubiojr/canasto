class AssetManagerCustomView < NSView

  def initWithFrame(rect)
    super rect
    @userDefaults = NSUserDefaults.standardUserDefaults
    @nQueue = NSNotificationQueue.defaultQueue
    registerForDraggedTypes [NSFilenamesPboardType, NSStringPboardType]
    self
  end

  def draggingEntered sender 
    CanastoLog.debug "draggingEntered:"
    if sender.draggingSource == self
        return NSDragOperationNone
    end
    return NSDragOperationCopy
  end

  def draggingExited sender
    CanastoLog.debug "draggingExited:"
  end

  def prepareForDragOperation sender
    true
  end

  def performDragOperation sender 
    CanastoLog.debug 'performDragOp'
    pb = sender.draggingPasteboard
    files = pb.stringForType NSFilenamesPboardType
    if files
      dc = @userDefaults.dictionaryForKey('NCXDropConfigs')
      ds = @userDefaults.objectForKey('NCXLastDropSelected') || dc.keys.first
      dropName = nil
      adminToken = nil
      dc.each do |k,v|
        if k == ds
          dropName = k
          adminToken = v
        end
      end
      pfiles = []
      files.each_line do |l|
        if l =~ /<string>(.*)<\/string>/
          pfiles << $1
        end
      end
      #plist = Plist::parse_xml(files)
      notifObj = {
        :dropName => dropName,
        :adminToken => adminToken,
        :files => pfiles
      }
      n = NSNotification.notificationWithName 'SendFiles', :object => notifObj
      @nQueue.enqueueNotification n, :postingStyle => NSPostWhenIdle
      return true
    else
      return false
    end
  end
 
  def concludeDragOperation sender 
   CanastoLog.debug "concludeDragOperation:"
  end

end
