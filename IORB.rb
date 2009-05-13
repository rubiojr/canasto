module IORB
  class DropManager
    def self.each
      drops = YAML.load_file(IORB::Config.file)['mydrops']
      if not drops.nil?
        drops.each do |key, val|
          next if val['destroyed'] == true
          yield IORB::DropDetails.build_from(val)
        end
      end
    end
    def self.find(name)
      each do |details|
        return details if details['name'] == name
      end
      nil
    end
  end

  class Config

    def self.exist?
      return File.exist?(self.file)
    end

    def self.file
      "#{ENV['HOME']}/.iorbrc"
    end

    def self.api_key
      YAML.load_file(self.file)['api-key']
    end
  end

  class DropDetails < Hash

    def method_missing(id, *args)
      if id.eql?(:admin_token) and self[id.to_s.gsub('_', '-')].nil?
        return nil
      end
      self[id.to_s.gsub('_', '-')] || super
    end

    def self.build_from(drop)
      details = DropDetails.new
      if drop.is_a? Dropio::Drop
        details['name'] = drop.name
        details['email'] = drop.email
        details['admin-url'] = drop.generate_url
        details['admin-token'] = drop.admin_token
        details['public-url'] = "http://drop.io/#{drop.name}"
        details['hidden-uploads'] = drop.hidden_upload_url
        details['max-bytes'] = drop.max_bytes
        details['password'] = drop.password
        details['admin-password'] = drop.admin_password
        details['expiration-length'] = drop.expiration_length
        details['guests-can-add'] = drop.guests_can_add
        details['guests-can-comment'] = drop.guests_can_comment
        details['guests-can-delete'] = drop.guests_can_delete
        details['current-bytes'] = drop.current_bytes
      else
        details['name'] = drop['name']
        details['email'] = drop['email']
        details['admin-url'] = drop['admin-url']
        details['admin-token'] = drop['admin-token']
        details['public-url'] = "http://drop.io/#{drop['name']}"
        details['hidden-uploads'] = drop['hidden-uploads']
        details['max-bytes'] = drop['max-bytes']
        details['created-at'] = drop['created-at']
        details['password'] = drop['password']
        details['admin-password'] = drop['admin-password']
        details['expiration-length'] = drop['expiration-length']
        details['guests-can-add'] = drop['guests-can-add']
        details['guests-can-comment'] = drop['guests-can-comment']
        details['guests-can-delete'] = drop['guests-can-delete']
        details['current-bytes'] = drop['current-bytes']
      end
      details
    end

    def save
      config = YAML.load_file(IORB::Config.file)
      config['mydrops'] = {} if config['mydrops'].nil?
      config['mydrops'][self['name']] = {}.merge(self)
      File.open(IORB::Config.file, 'w') do |f|
        f.puts config.to_yaml
      end
    end
  end

end
