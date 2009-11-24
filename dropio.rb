module Canasto
  module DropIO
    class Config
      def self.api_key=(key)
        @@api_key = key
      end

      def self.api_key
        @@api_key
      end
    end
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

      def self.load(name, token=nil)
        Drop.new(Crack::JSON.parse(RestClient.get "http://api.drop.io/drops/#{name}?api_key=#{DropIO::Config.api_key}&format=json&version=2.0&token=#{token}"))
      end
    end
  end
end
