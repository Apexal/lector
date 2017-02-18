module Lector
  module Scraper
    @agent = Mechanize.new
    @agent.user_agent_alias = 'Linux Firefox'

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
      raise InvalidPageError, "Name is too short: '#{page.title}'" if page.title.split(':').length < 2

      page
    end

    def self.extract_person(id, page)
      title = page.title

      name = title.split(':')[0].split(' ')
      first_name = name[0]
      last_name = name[1..-1].join(' ')

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
        pictureurl: picture_url,
        username: username_guess,
        course_ids: page.search("//dd/ul/li/a[contains(@href, 'http://moodle.regis.org/course/view.php?id=')]").map { |link| link["href"].split("id=")[1].split("&")[0] }
      }

      if type == :student
        returning[:graduation_year] = info['graduation_year']
        returning[:address] = info['resident_address'].sub('<br />', ' ')
      end

      returning
    end

    def self.extract_course(id, page)
      parts = page.title.split(':')
      is_class = parts.length > 2 # Classes have a teacher, title would have ': Teacher Name'

      # Course: Theater Production: Grunner
      title = (parts.length == 1 ? parts[0]  : parts[1]).strip

      returning = {
        id: id,
        title: title,
        is_class: is_class
      }

      if is_class
         # Find teacher
        teacher_page = @agent.get("http://moodle.regis.org/user/index.php?roleid=3&sifirst=&silast=&id=#{id.to_s}")
        returning[:teacher_id] = teacher_page.search("//strong/a[contains(@href, 'moodle.regis.org')]")[0]['href'].split("?id=")[1].split("&course=")[0].to_i
      end

      puts "#{id}: Course #{parts[1..-1].join(' ')}#{" (class)" if is_class}"

      returning
    end
  end
end