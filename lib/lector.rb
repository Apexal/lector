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
  @@defaults = {
    db_host: 'localhost',
    db_database: 'lector',
    db_username: 'root',
    db_password: '',
    regis_username: '',
    regis_password: '',
    veracross_path: "#{Dir.pwd}/data/veracross.json"
  }

  VERSION = "0.9.0"

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
    login_to_moodle

    # Connect to DB
    connect_db

    nil
  end

  def scrape_and_save(id, type)
    puts "Scraping and saving #{type.to_s} with Moodle ID #{id}"
    begin
      return case type
        when :person
          save_person(extract_person(id))
        when :course
          save_course(extract_course(id))
      end
    rescue => e
      puts "Failed to scrape and save #{type.to_s} with ID: #{id}\n#{e}"
    end
  end
end