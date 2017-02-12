module Lector
  class Config
    include StoreData

    @@defaults = {
      db_host: 'localhost',
      db_database: 'lector',
      db_username: 'root',
      db_password: ''
    }

    def initialize
      @path = "#{Dir.pwd}/data/config.yaml"
      puts "Loading config file at #{@path}"

      temp = load_file(@path)

      @config = temp if temp.is_a?(Hash) && !temp.empty?
      setup if @config.nil?
      create_methods
    end

    private
      def setup
        @config = {}

        @@defaults.each do |key, value|
          print "#{key}: (#{value}) "
          entered = gets.chomp
          @config[key] = (entered.empty? ? value : entered)
        end
        
        save_to_file(@path, @config)
      end

      def create_methods
        @config.keys.each do |key|
          self.class.send(:define_method, key) do
            @config[key]
          end
        end
      end
  end
end