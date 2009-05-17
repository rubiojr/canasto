class DropManagerDocument < NSDocument

  attr_accessor :dropConfigs
  attr_accessor :tableView, :dropConfigsController
  attr_accessor :currentDropMenu
  attr_accessor :appController
  attr_reader :path

  def init
    super
    @path = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, true).last.to_s + "/LittleDrop/Drops"
    @dropConfigs = Array.new
    url = NSURL.fileURLWithPath @path
    errorp = Pointer.new_with_type('@')
    readFromURL url, :ofType => "text/plain", :error => errorp
    self
  end

  def setDropConfigs(a)
    @dropConfigs = a
  end
  
  def updateMenus
    @currentDropMenu.itemArray.each do |mi|
      @currentDropMenu.removeItem mi
    end
    @dropConfigs.each do |c|
      mi = NSMenuItem.alloc.init
      mi.title = c.dropName
      mi.action = 'dropSelected:'
      mi.setTarget @appController
      mi.state = NSOffState
      @currentDropMenu.addItem mi
    end
  end

  def createDropConfig(sender)
    w = @tableView.window
    b = w.makeFirstResponder w

    dc = DropConfig.new
    @dropConfigsController.addObject dc
    a = @dropConfigsController.arrangedObjects
    @tableView.editColumn 0, :row => (a.indexOfObjectIdenticalTo dc),
                :withEvent => nil, :select => true
  end

  def saveDropConfigs(sender)
    url = NSURL.fileURLWithPath @path
    errorp = Pointer.new_with_type('@')
    writeToURL url, :ofType => "text/plain", :error => errorp
    updateMenus
  end

  def dataOfType(typeName, error:error)
    #NSKeyedArchiver.archivedDataWithRootObject ['foo', 'bar', 'stuff']
    NSKeyedArchiver.archivedDataWithRootObject @dropConfigs
  end

  def readFromData(data, ofType:typeName, error:error)
    newArray = NSKeyedUnarchiver.unarchiveObjectWithData data
    @dropConfigs = newArray
    return true
  end

  #def dataRepresentationOfType(type)
  #  puts 'bar'
  #  puts @dropConfigs
  #  NSKeyedArchiver.archivedDataWithRootObject @dropConfigs
  #end

  #def loadDataRepresentation(data, ofType:type)
  #  puts 'foo'
  #  @packModel = NSKeyedUnarchiver.unarchiveObjectWithData data
  #  setNeedsDisplay true
  #  true
  #end

end
