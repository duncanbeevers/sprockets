module Sprockets
  class Environment
    attr_reader :root, :load_path
    
    def initialize(root, load_path = [], constants_from_config = {})
      @constants_from_config = constants_from_config
      @load_path = [@root = Pathname.new(self, root)]

      load_path.reverse_each do |location|
        register_load_location(location)
      end
    end
    
    def pathname_from(location)
      Pathname.new(self, absolute_location_from(location))
    end

    def register_load_location(location)
      pathname = pathname_from(location)
      load_path.delete(pathname)
      load_path.unshift(pathname)
      location
    end
    
    def find(location)
      if Sprockets.absolute?(location) && File.exists?(location)
        pathname_from(location)
      else
        find_all(location).first
      end
    end
    
    def constants(reload = false)
      @constants = nil if reload
      @constants ||= constants_from_disk(reload).merge(constants_from_config)
    end
    
    def constants_from_disk(reload = false)
      @constants_from_disk = nil if reload
      @constants_from_disk ||= find_all("constants.yml").inject({}) do |constants, pathname|
        contents = YAML.load(pathname.contents) rescue nil
        contents = {} unless contents.is_a?(Hash)
        constants.merge(contents)
      end
    end
    
    def constants_from_config
      @constants_from_config
    end
    
    protected
      def absolute_location_from(location)
        location = location.to_s
        location = File.join(root.absolute_location, location) unless Sprockets.absolute?(location)
        File.expand_path(location)
      end
      
      def find_all(location)
        load_path.map { |pathname| pathname.find(location) }.compact
      end
  end
end
