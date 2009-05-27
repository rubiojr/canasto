class GrowlController
  attr_accessor :app

  def initialize
    @g = Growl::Notifier.sharedInstance
    @g.register 'LittleDrop', ['AssetAdded', 'AssetRemoved', 'DropDestroyed', 'DropCreated']
    super
  end

  def assetAdded(asset_name, drop_name)
    @g.notify 'AssetAdded', 'drop.io', "Asset #{asset_name} added to #{drop_name}"
  end

  def assetRemoved(asset_name, drop_name)
    @g.notify 'AssetRemoved', 'drop.io', "Asset #{asset_name} removed from #{drop_name}"
  end
  def dropSelected(drop_name)
    @g.notify 'AssetRemoved', 'drop.io', "Drop #{drop_name} selected"
  end
  def dropSelected(drop_name)
    @g.notify 'DropCreated', 'drop.io', "Drop #{drop_name} created"
  end
  
  def addingAsset(drop_name, asset_name)
    @g.notify 'LittleDrop', 'drop.io', "Adding asset #{asset_name} to #{drop_name}"
  end
  def dropDestroyed(drop_name)
    @g.notify 'DropDestroyed', 'drop.io', "Drop #{drop_name} has been destroyed!"
  end

  def error(msg)
    @g.notify 'LittleDrop', 'drop.io error!', msg
  end
end
