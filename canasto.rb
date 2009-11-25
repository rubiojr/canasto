require 'crack'
require 'restclient'
require 'logger'

module Canasto
  
  API_URL = 'http://api.drop.io'

  def self.api_key_valid?
    begin
      RestClient.get "#{API_URL}/drops/sscanasto?api_key=#{Canasto::Config.api_key}&version=2.0"
      return true
    rescue RestClient::RequestFailed
      return false
    rescue Exception
      return true
    end
  end

  class Config
    def self.api_key=(key)
      @@api_key = key
    end

    def self.api_key
      @@api_key
    end
  end

  #
  # Properties in API v2.0
  # asset_count
  # 
  class Drop
    def initialize(json)
      @json = json
    end

    def method_missing(mid)
      if @json.has_key? mid.to_s
        @json[mid.to_s]
      else
        super
      end
    end

    def admin?
      @json.has_key? 'admin_token'
    end

    def self.exist?(name)
      !self.load(name.to_s).nil?
    end

    def self.load(name, token=nil)
      begin
        response = RestClient.get("http://api.drop.io/drops/#{name}?api_key=#{Canasto::Config.api_key}&format=json&version=2.0&token=#{token || ''}")
        Drop.new(Crack::JSON.parse(response))
      rescue
        nil
      end
    end

    def guests_can_add?
      guests_can_add
    end

    def guests_can_delete?
      guests_can_delete
    end

    def guests_can_comment?
      guests_can_comment
    end
    
    def guests_can_comment?
      guests_can_comment
    end

    def guests_can_download?
      guests_can_download
    end
    
    def guests_can_download?
      guests_can_reorder
    end

    def set_readonly_guest_permissions
      update :guests_can_add => false,
             :guests_can_delete => false,
             :guests_can_reorder => false
    end

    def set_paranoid_guest_permissions
      update :guests_can_add => false,
             :guests_can_delete => false,
             :guests_can_reorder => false,
             :guests_can_chat => false,
             :guests_can_download => false,
             :guests_can_comment => false
    end

    def set_permissive_guest_permissions
      update :guests_can_add => true,
             :guests_can_delete => true,
             :guests_can_reorder => true,
             :guests_can_chat => true,
             :guests_can_download => true,
             :guests_can_comment => true
    end

    #
    # Raises an exception if not admin
    # Raises exception if RestClient raises an exception
    # 
    def update(params={})
      raise Exception.new('Invalid admin token') if !admin?
      params.merge!({
        :api_key => Canasto::Config.api_key,
        :format => 'json',
        :version => '2.0',
        :token => admin_token
      })
      require 'pp'
      @json = Crack::JSON.parse(RestClient.put("#{API_URL}/drops/#{name}", params))
    end
  end
end

