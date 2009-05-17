class DropConfig 

  attr_accessor :dropName, :adminToken

  def initialize
    @dropName = 'Edit Me'
    @adminToken = 'FFFFFF'
  end

  def encodeWithCoder(coder)
    coder.encodeObject @dropName, :forKey => "dropName" 
    coder.encodeObject  @adminToken, :forKey => "adminToken"
  end

  def initWithCoder(coder)
    @dropName = coder.decodeObjectForKey "dropName"
    @adminToken = coder.decodeObjectForKey "adminToken" 
    return self; 
  end

end
