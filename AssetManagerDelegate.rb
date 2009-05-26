class AssetManagerDelegate
  attr_writer :drawer

  def windowShouldClose(window)
    @drawer.close self
    true
  end
end
