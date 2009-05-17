class Preferences

  def self.appSupportDir
    NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, true).last.to_s + "/LittleDrop"
  end

  def self.dropsConfigFile
    appSupportDir + '/DropsConfig'
  end
end
