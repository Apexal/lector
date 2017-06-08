require 'test_helper'

class LectorTest < Minitest::Test
  def test_that_it_has_a_version_number
    puts "VERSION v#{::Lector::VERSION}"
    refute_nil ::Lector::VERSION
  end

  def test_loads_config_file
    path = "/home/frank/Projects/lector/data/config.yaml"

    ::Lector.new(YAML.load_file(path))
  end

  def test_that_it_fails_to_login_with_false_credentials
    puts 'Testing'
    fake_credentials = {regis_username: 'fake', regis_password: 'fake'}
    
    err = assert_raises ::Lector::Exceptions::InvalidCredentialsError do ::Lector.new(fake_credentials) end
    puts err
  end
end
