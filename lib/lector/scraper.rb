module Lector
  module Scraper
    @agent = Mechanize.new

    SUCCESSFUL_LOGIN_PAGE_TITLE = 'Dashboard'
    IGNORE_TITLES = %w(Notice Error Test Parent Nurse)

    def self.login
      page = @agent.post('https://moodle.regis.org/login/index.php', {
        username: Lector::CONFIG.regis_username,
        password: Lector::CONFIG.regis_password,
      })

      raise InvalidCredentialsError unless page.title == SUCCESSFUL_LOGIN_PAGE_TITLE

      true
    end

    def self.get_profile(id, type)
      base_url = (type == :person ? 'http://moodle.regis.org/course/view.php?id=' : 'http://moodle.regis.org/user/profile.php?id=')

      # Request page
      page = @agent.get(base_url + id.to_s)

      # Discard unneccessary pages
      return if IGNORE_TITLES.any? { |w| page.title.downcase.include?(w.downcase) }

      page
    end

    def self.extract_person(id, page)
      title = page.title

      name = title.split(':')[0].split(' ')
      first_name = name[0]
      last_name = names[1..-1]

      raise InvalidPageError, 'Student test account.' if name.include?('Student')
      raise InvalidPageError, 'Test account.' if name.include?('Test')
      raise InvalidPageError, 'Parent account.' if name.include?('Parent')
      raise InvalidPageError, 'Name is only one word.' if first_name.empty? || last_name.empty?

      picture_url = nil
      begin
        picture_url = page.search("a/img[@alt=\"Picture of #{first_name} #{last_name}\"]")[0]['src']
      rescue
        puts "Failed to get image of person with MID #{mid}"
        raise InvalidPageError, 'Page doesn\'t have picture.'
      end

      # DEPARTMENT (advisement for students, subject for staff)
      department = page.search("//dd[../dt = 'Department']/text()").to_s

      type = (/\A\d+\z/.match(department[0]) || department.empty? ? :student : :staff)

      username_guess = (type == :staff ? "#{first_name[0]}#{last_name}" : "#{first_name[0]}#{last_name}#{Lector::ADVISEMENT_TO_GRAD_YEAR[department[0]]}")

      # FIND INFO FROM VERACROSS
      Lector::Veracross::find_by_username()

      puts "#{id}: #{type.capitalize} #{last_name}, #{first_name} of #{department}"

      return {
        type: type,
        first_name: first_name,
        last_name: last_name,
        department: department,
        username: username
      }
    end

    def self.extract_course(id, page)

    end

  
  end
end