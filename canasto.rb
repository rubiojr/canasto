require 'crack'
require 'restclient'
require 'logger'
require 'pp'

module Canasto
  API_URL = 'http://api.drop.io'
  ASSETS_API_URL = 'http://assets.drop.io/upload'

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
  
  class DropIOObject
    def initialize(json)
      @json = json
    end

    def method_missing(mid)
      if @json.has_key? mid.to_s
        @json[mid.to_s]
      else
        nil
      end
    end

    def to_s
      @json.inspect
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
  class Drop < DropIOObject
    def assets
      CanastoLog.debug "Inside Canasto::Drop.assets"
      a = []
      list = get_api_query("/drops/#{name}/assets")['assets']
      list.each do |asset|
        a << Asset.new(asset)
      end
      a
    end

    def upload_files(files)
      files.each do |f|
        if File.exist?(f)
          add_file(f)
        else
          CanastoLog.warn "File #{f} does not exist"
        end
      end
    end

    def delete_asset(asset_name)
      delete_api_query("/drops/#{name}/assets/#{asset_name}")
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
      params = build_query_params(params)
      @json = Crack::JSON.parse(RestClient.put("#{API_URL}/drops/#{name}", params))
    end

    def build_query_params(params = {})
      params.merge({
        :api_key => Canasto::Config.api_key,
        :format => 'json',
        :version => '2.0',
        :token => admin_token
      })
    end

    def get_api_query(method, params = {})
      CanastoLog.debug "Inside get_api_query, method #{method}"
      qstring = ""
      p = build_query_params(params)
      p.each do |k,v|
        qstring << "#{k.to_s}=#{v}&"
      end
      CanastoLog.debug "sending RestClient.get in get_api_query"
      req = RestClient.get("#{API_URL}/#{method}?#{qstring}")
      CanastoLog.debug "parsing JSON in get_api_query"
      resp = Crack::JSON.parse(req)
      CanastoLog.debug "Outside get_api_query"
      resp
    end

    def delete_api_query(method, params = {})
      CanastoLog.debug "Inside delete_api_query"
      qstring = ""
      params = build_query_params(params)
      params.each do |k,v|
        qstring << "#{k.to_s}=#{v}&"
      end
      Crack::JSON.parse(RestClient.delete("#{API_URL}/#{method}?#{qstring}"))
    end

    def add_file(file_path)
      CanastoLog.debug 'Inside add_file'
      url = URI.parse("http://assets.drop.io/upload/")
      r = nil
      CanastoLog.debug 'Opening file in Canasto::Drop.add_file'
      mime_type = "application/octet-stream"
      params = { 'api_key' => Canasto::Config.api_key,
        'drop_name' => name,
        'format' => 'json',
        'token' => admin_token,
        'version' => '2.0', 
        'file' => File.new(file_path)
      }
      CanastoLog.debug 'Doing post file'
      `curl -X POST -F 'file=@#{file_path}' -F'drop_name=#{name}' -F'token=#{admin_token}' -F'version=2.0' -F'api_key=#{Canasto::Config.api_key}' #{ASSETS_API_URL} > /dev/null`
      CanastoLog.debug 'File posted!'
    end

  end

  class Asset < DropIOObject
  end

end

