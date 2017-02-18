module Lector
  module Scraper
    @agent = Mechanize.new

    SUCCESSFUL_LOGIN_PAGE_TITLE = 'Dashboard'
    IGNORE_TITLES = %w(Notice Error Test Parent Nurse Student)

    def self.login
      page = @agent.post('https://moodle.regis.org/login/index.php', {
        username: Lector::CONFIG.regis_username,
        password: Lector::CONFIG.regis_password,
      })

      raise InvalidCredentialsError, 'Invalid Regis credentials! Couldn\'t log into Moodle.' unless page.title == SUCCESSFUL_LOGIN_PAGE_TITLE
    end

    def self.get_profile(id, type)
      base_url = (type == :person ? 'http://moodle.regis.org/user/profile.php?id=' : 'http://moodle.regis.org/course/view.php?id=')

      # Request page
      page = @agent.get(base_url + id.to_s)

      # Discard unneccessary pages
      raise InvalidPageError, "Invalid page: '#{page.title}'" if IGNORE_TITLES.any? { |w| page.title.downcase.include?(w.downcase) }
      raise InvalidPageError, "Name is too short: '#{page.title.split(':')[0]}'" if page.title.split(':')[0].split(' ').length < 2

      page
    end

    def self.extract_person(id, page)
      title = page.title

      name = title.split(':')[0].split(' ')
      first_name = name[0]
      last_name = name[1..-1].join(' ')

      puts name

      picture_url = nil
      begin
        picture_url = page.search("a/img[@alt=\"Picture of #{first_name} #{last_name}\"]")[0]['src']
      rescue => e
        puts e
        raise InvalidPageError, 'Page doesn\'t have picture.'
      end

      # DEPARTMENT (advisement for students, subject for staff)
      department = page.search("//dd[../dt = 'Department']/text()").to_s

      type = (/\A\d+\z/.match(department[0]) || department.empty? ? :student : :staff)

      username_guess = (type == :staff ? "#{first_name[0]}#{last_name}" : "#{first_name[0]}#{last_name}#{Lector::ADVISEMENT_TO_GRAD_YEAR[department[0]]}").downcase.gsub("'", '').gsub('-', '').gsub(' ', '')

      # FIND INFO FROM VERACROSS
      info = Veracross::find_by_username_or_email(username_guess)
      puts "#{id}: #{type.capitalize} #{last_name}, #{first_name} of #{department}"

      returning =  {
        type: type,
        first_name: first_name,
        last_name: last_name,
        department: department,
        username: username_guess,
        course_ids: page.search("//dd/ul/li/a[contains(@href, 'http://moodle.regis.org/course/view.php?id=')]").map { |link| link["href"].split("id=")[1].split("&")[0] }
      }

      if type == :student
        returning[:graduation_year] = info['graduation_year']
        returning[:address] = info['resident_address'].sub('<br />', ' ')
      else

      end

      returning
    end

    def self.extract_course(id, page)

    end

  
  end
end