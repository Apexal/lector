module Lector
  module Database
    ActiveRecord::Base.establish_connection(
      adapter: 'mysql2',
      host: '',
      database: '',
      username: '',
      password: ''
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

  end
end