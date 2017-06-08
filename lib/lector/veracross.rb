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

  def load_veracross
    puts "Loading Veracross data from #{@config[:veracross_path]}"
    path = @config[:veracross_path]
    @data = JSON.load(File.read(path))

    puts "Loaded #{@data.length} students"
  end

  def find_by_username_or_email(u_or_e)
    load if @data.nil?
    email = (u_or_e.end_with?('@regis.org') ? u_or_e : u_or_e + '@regis.org')
    @data.find { |entry| entry['email'] == email }
  end
end
