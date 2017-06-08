module Scraper
  include Exceptions
  include Veracross

  # Constants
  AGENT = Mechanize.new
  AGENT.user_agent_alias = 'Linux Firefox'
  
  GRADES = %w(Freshmen Sophomores Juniors Seniors).freeze
  SINGULAR_GRADES = %w(Freshman Sophomore Junior Senior).freeze
  ADVISEMENT_TO_GRAD_YEAR = {'1' => 20, '2' => 19, '3' => 18, '4' => 17}

  SUCCESSFUL_LOGIN_PAGE_TITLE = 'Dashboard'
  IGNORE_TITLES = %w(Notice Error Test Parent Nurse Student)

  def login_to_moodle
    puts "Attempting to login to Moodle as #{@config[:regis_username]}..."
    puts AGENT
    page = AGENT.post('https://moodle.regis.org/login/index.php', {
      username: @config[:regis_username],
      password: @config[:regis_password],
    })

    raise InvalidCredentialsError, 'Invalid Regis credentials! Couldn\'t log into Moodle.' unless page.title == SUCCESSFUL_LOGIN_PAGE_TITLE

    true
  end

  def get_profile(id, type)
    base_url = (type == :person ? 'http://moodle.regis.org/user/profile.php?id=' : 'http://moodle.regis.org/course/view.php?id=')

    # Request page
    page = AGENT.get(base_url + id.to_s)

    # Discard unneccessary pages
    raise InvalidPageError, "Invalid page: '#{page.title}'" if page.title.nil? || IGNORE_TITLES.any? { |w| page.title.downcase.include?(w.downcase) }
    raise InvalidPageError, "Name is too short: '#{page.title}'" if page.title.split(':').length < 2

    page
  end

  def extract_person(id)
    page = get_profile(id, :person)
    
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

    returning = {
      id: id,
      type: type,
      first_name: first_name,
      last_name: last_name,
      email: username_guess + '@regis.org',
      department: department,
      pictureurl: picture_url,
      username: username_guess,
      course_ids: page.search("//dd/ul/li/a[contains(@href, 'http://moodle.regis.org/course/view.php?id=')]").map { |link| link["href"].split("id=")[1].split("&")[0] }
    }

    if type == :student
      # FIND INFO FROM VERACROSS
      info = find_by_username_or_email(username_guess)
      raise InvalidPageError, 'Student doesn\'t exist. Failed to link to Veracross data.' if info.nil?

      returning[:advisement] = returning.delete(:department)
      returning[:veracross_id] = info['person_pk']
      returning[:pictureurl] = info['photo_url']
      returning[:graduation_year] = info['graduation_year']
      returning[:address] = info['resident_address'].sub('<br />', ' ')
      returning[:birthday] = Date.parse(info['birthday'])
    end

    puts "#{id}: #{type.capitalize} #{last_name}, #{first_name} of #{department} (#{username_guess})"

    returning
  end

  def extract_course(id)
    page = get_profile(id, :course)

    parts = page.title.split(':')
    is_class = parts.length > 2 # Classes have a teacher, title would have ': Teacher Name'

    # Course: Theater Production: Grunner
    title = (parts.length == 1 ? parts[0]  : parts[1]).strip

    returning = {
      type: :course,
      id: id,
      title: title,
      is_class: is_class
    }

    if is_class
      # Find teacher
      teacher_page = AGENT.get("http://moodle.regis.org/user/index.php?roleid=3&sifirst=&silast=&id=#{id.to_s}")
      returning[:teacher_id] = teacher_page.search("//strong/a[contains(@href, 'moodle.regis.org')]")[0]['href'].split("?id=")[1].split("&course=")[0].to_i
    end

    puts "#{id}: Course #{parts[1..-1].join}#{" (class)" if is_class}"

    returning
  end

end
