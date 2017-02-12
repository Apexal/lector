require 'rubygems'

require 'yaml'
require 'mysql2'
require 'active_record'

require_relative 'lector/version'
require_relative 'lector/storedata'

module Lector
  # Constants
  GRADES = %w(Freshmen Sophomores Juniors Seniors).freeze
  SINGULAR_GRADES = %w(Freshman Sophomore Junior Senior).freeze

  require_relative 'lector/config'
  CONFIG = Config.new

  # Require all modules
  Dir["#{File.dirname(__FILE__)}/regit/*.rb"].each { |file| require file }

end
