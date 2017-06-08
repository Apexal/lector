require 'rubygems'

require 'date'
require 'yaml'
require 'mysql2'
require 'active_record'
require 'mechanize'

require 'bundler/setup'
Bundler.setup(:default)

# Require all modules
Dir["#{File.dirname(__FILE__)}/lector/*.rb"].each { |file| require file }

class Lector
  attr_accessor :logged_in

  @@defaults = {
    db_host: 'localhost',
    db_database: 'lector',
    db_username: 'root',
    db_password: '',
    regis_username: '',
    regis_password: '',
    veracross_path: "#{Dir.pwd}/data/veracross.json"
  }

  VERSION = "0.2.2"

  include Database
  include Veracross
  include Scraper

  attr_reader :logged_in

  def initialize(config)
    puts "Lector v#{VERSION}"

    # Fill in any blanks
    @config = @@defaults.merge(config)
    load_veracross

    # First try to login to Moodle
    @logged_in = login_to_moodle
    
    # Connect to DB
    connect_db

    nil
  end
end