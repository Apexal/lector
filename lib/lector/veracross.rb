module Lector
  module Veracross
    # USEFUL PROPERTIES
    # first_name
    # last_name
    # birthday
    # grade_level
    # graduation_year
    # advisor
    # address
    # email

    def self.load
      path = Lector::CONFIG.veracross_path
      @data = JSON.load(File.read(path))
    end
    
    def self.find_by_username_or_email(u_or_e)
      load if @data.nil?
      email = (u_or_e.end_with?('@regis.org') ? u_or_e : u_or_e + '@regis.org')
      @data.find { |entry| entry['email'] == email }
    end
  end
end