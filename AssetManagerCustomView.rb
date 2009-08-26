class AssetManagerCustomView < NSView

  def initWithFrame(rect)
    super rect
    @userDefaults = NSUserDefaults.standardUserDefaults
    @nQueue = NSNotificationQueue.defaultQueue
    registerForDraggedTypes [NSFilenamesPboardType, NSStringPboardType]
    self
  end

  def draggingEntered sender 
    NSLog("draggingEntered:")
    if sender.draggingSource == self
        return NSDragOperationNone
    end
    return NSDragOperationCopy
  end

  def draggingExited sender
    NSLog("draggingExited:")
  end

  def prepareForDragOperation sender
    true
  end

  def performDragOperation sender 
    NSLog 'performDragOp'
    pb = sender.draggingPasteboard
    file = pb.stringForType NSFilenamesPboardType
    if file
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
      plist = Plist::parse_xml(file)
      notifObj = {
        :dropName => dropName,
        :adminToken => adminToken,
        :files => plist
      }
      n = NSNotification.notificationWithName 'SendFiles', :object => notifObj
      @nQueue.enqueueNotification n, :postingStyle => NSPostWhenIdle
      return true
    else
      return false
    end
  end
 
  def concludeDragOperation sender 
   NSLog("concludeDragOperation:")
  end

end
