module Database
  def connect_db
    puts "Connecting to MySQL DB at #{@config[:db_host]}"
    ActiveRecord::Base.establish_connection(
      adapter: 'mysql2',
      host: @config[:db_host],
      database: @config[:db_database],
      username: @config[:db_username],
      password: @config[:db_password]
    )
  end

  class Student < ActiveRecord::Base
    has_and_belongs_to_many :courses
  end

  class Course < ActiveRecord::Base
    belongs_to :staff, inverse_of: :courses, foreign_key: 'teacher_id'
    has_and_belongs_to_many :students
  end

  class Staff < ActiveRecord::Base
    has_and_belongs_to_many :courses
  end

  # Determine staff or student
  def save_person(info)
    return case info[:type]
      when :student
        save_student(info)
      else
        save_staff(info)
      end
  end

  def save_course(info)
    info.delete(:type)

    # DB throws error if doesn't exist so resort to nil if throws
    course = Course.find(info[:id]) rescue nil

    if course.nil?  
      course = Course.create(info)
    else
      course.update(info)
    end

    course.save!
    course
  end

  def save_staff(info)
    info.delete(:type)

    # DB throws error if doesn't exist so resort to nil if throws
    staff = Staff.find(info[:id]) rescue nil

    course_ids = info.delete(:course_ids)

    if staff.nil?
      staff = Staff.create(info)
    else
      staff.update(info)
    end

    staff.courses = Course.where(id: course_ids)  # Throws error if courses don't exist

    staff.save!
    staff
  end

  def save_student(info)
    info.delete(:type)

    # DB throws error if doesn't exist so resort to nil if throws
    student = Student.find(info[:id]) rescue nil

    course_ids = info.delete(:course_ids)

    if student.nil?
      student = Student.create(info)
    else
      student.update(info)
    end

    student.courses = Course.where(id: course_ids) # Throws error if courses don't exist

    student.save!
    student
  end
end
