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
  end

  def save_student(info)
    info.delete(:type)

    # DB throws error if doesn't exist so resort to nil if throws
    student = Student.find(info[:id]) rescue nil

    course_ids = info[:course_ids]
    info.delete(:course_ids)

    if student.nil?
      student = Student.create(info)
      student.course_ids = course_ids
    else
      student.update(info)
      student.course_ids = course_ids # Throws error if courses don't exist
    end

    student.save!
  end
end
