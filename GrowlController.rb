class GrowlController
  attr_accessor :app

  def initialize
    @g = Growl::Notifier.sharedInstance
    @g.register 'Dropper', ['AssetAdded', 'AssetRemoved']
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

  def error(msg)
    @g.notify 'LittleDrop', 'drop.io', msg
  end
end
