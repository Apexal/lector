module Lector
  module Database
    ActiveRecord::Base.establish_connection(
      adapter: 'mysql2',
      host: Lector::CONFIG.db_host,
      database: Lector::CONFIG.db_database,
      username: Lector::CONFIG.db_username,
      password: Lector::CONFIG.db_password
    )

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

    def self.save_course(info)
      info.delete(type)

      course = Course.find(info[:id])
      
      if course.nil?  
        course = Course.create(info)
      else
        course.update(info)
      end

      course
    end
  end
end