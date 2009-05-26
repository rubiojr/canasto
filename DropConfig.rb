class DropConfig 

  attr_accessor :dropName, :adminToken

  def init
    super
    @dropName = 'New Drop'
    @adminToken = '00000'
    self
  end
end
