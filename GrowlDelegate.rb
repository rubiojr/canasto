class GrowlDelegate

  def applicationNameForGrowl
    'LittleDrop'
  end

  def growlIsReady
    @@growlReady = true
  end

  def self.notify(title, desc, notificationName)
    if defined? :growlReady
      GrowlApplicationBridge.notifyWithTitle title,
                              :description => desc,
                              :notificationName => notificationName,
                              :iconData => nil,
                              :priority => 0,
                              :isSticky => false,
                              :clickContext => nil
    end
  end
end
