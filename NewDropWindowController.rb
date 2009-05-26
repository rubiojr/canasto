class NewDropWindowController
  attr_accessor :dropName
  attr_accessor :password
  attr_accessor :guestCanAdd
  attr_accessor :guestCanDelete
  attr_accessor :guestCanComment
  attr_accessor :window

  def create(sender)
    opQueue = NSOperationQueue.alloc.init
    properties = {
      'dropName' => @dropName,
    }
    if @password
      properties.merge( { 'password' => @password } )
    end
    op = CreateDropOperation.alloc.init
    op.properties = properties
    opQueue.addOperation op
    @window.performClose self
  end
end
