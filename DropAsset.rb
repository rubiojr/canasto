class DropAsset
 
  attr_accessor :name, :type, :fileSize, :createdAt, :URL

  def init
    super
    @name = ''
    @type = ''
    @fileSize = ''
    @createdAt = ''
    @URL = ''
    self
  end

end
