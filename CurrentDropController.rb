class CurrentDropController

  def currentDrop
    @currentDrop
  end

  def currentDrop=(drop_name)
    NSRunLoop.currentRunLoop.performSelector 'changeCurrentDrop:', :target => self, :argument => drop_name, :order => 0, :modes => [NSDefaultRunLoopMode]
  end

  private
  def changeCurrentDrop(dropName)
    adminToken = NSUserDefaults.standardUserDefaults.dictionaryForKey('NCXDropConfigs')[dropName]
    if adminToken.nil?
      CanastoLog.error("CurrentDropController: drop config not found in changeCurrentDrop")
    end
    @currentDrop = Canasto::Drop.load dropName, adminToken
  end

end
