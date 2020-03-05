require 'bundler/setup'
Bundler.require

if development?
  ActiveRecord::Base.establish_connection("sqlite3:db/development.db")
end

class User < ActiveRecord::Base
  has_many :tasks
  has_many :costs
end

class Task < ActiveRecord::Base
  belongs_to :user
  has_many :costs
  has_one :estimation
  has_one :feed_back
end

class Cost < ActiveRecord::Base
  belongs_to :user
  belongs_to :task
  has_many :estimations
  has_many :feedbacks
end

class Estimation < ActiveRecord::Base
  belongs_to :task
  belongs_to :cost
  has_one :feedback
end

class Feedback < ActiveRecord::Base
  belongs_to :task
  belongs_to :cost
  belongs_to :estimation
end