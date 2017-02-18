require 'rubygems'

require 'yaml'
require 'mysql2'
require 'active_record'
require 'mechanize'

require 'bundler/setup'
Bundler.setup(:default)

require_relative 'lector/version'
require_relative 'lector/other/storedata'

module Lector
  # Constants
  GRADES = %w(Freshmen Sophomores Juniors Seniors).freeze
  SINGULAR_GRADES = %w(Freshman Sophomore Junior Senior).freeze
  ADVISEMENT_TO_GRAD_YEAR = {'1' => 20, '2' => 19, '3' => 18, '4' => 17}
  require_relative 'lector/config'
  CONFIG = Config.new

  # Require all modules
  Dir["#{File.dirname(__FILE__)}/lector/*.rb"].each { |file| require file }

  begin
    Scraper.login
    puts "Successfully logged into Moodle as #{CONFIG.regis_username}..."

  rescue => e
    puts "There was an error: #{e}\nQuitting..."
    puts e.backtrace
  end
end