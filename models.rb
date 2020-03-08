require 'bundler/setup'
Bundler.require

if development?
  ActiveRecord::Base.establish_connection("sqlite3:db/development.db")
end

class User < ActiveRecord::Base
  has_many :tasks
end

class Task < ActiveRecord::Base
  belongs_to :user
  has_one :task_scale
  has_one :task_period
  has_one :task_manhour
  has_one :task_experience

  has_many :hashtags
  has_many :tag_types, through: :hashtags, source: :tag
# DBへpostがcreateされた直後に実行
  after_create do
    # controller側でcreateしたtweetを取得
    task = Task.find_by(id: self.id)
    # 正規表現
    tags = self.tag_text.scan(/[#＃][Ａ-Ｚａ-ｚA-Za-z一-鿆0-9０-９ぁ-ヶｦ-ﾟー]+/)
    # mapで要素を１つ１つ取り出して、先頭の＃を除いてDBへ保存する。
    tags.uniq.map do |t|
      tag = Tag.find_or_create_by(hashtag: t.downcase.delete('#'))
      post.tag_types << tag
    end
  end
  def parameter_register()
    self.task_scale.create()
    self.task_period.create()
    self.task_manhour.create()
    self.task_experience.create()
  end
end

class Estimation < ActiveRecord::Base
  belongs_to :task_scale
  belongs_to :taak_period
  belongs_to :task_manhour
  belongs_to :task_experience
end

class Feedback < ActiveRecord::Base
  belongs_to :task_scale
  belongs_to :taak_period
  belongs_to :task_manhour
  belongs_to :task_experience
end

class TaskScale < ActiveRecord::Base
  belongs_to :task
  has_many :estimation
  has_many :feedback
end

class TaskPeriod < ActiveRecord::Base
  belongs_to :task
  has_many :estimation
  has_many :feedback
end

class TaskManhour < ActiveRecord::Base
  belongs_to :task
  has_many :estimation
  has_many :feedback
end

class TaskExperience < ActiveRecord::Base
  belongs_to :task
  has_many :estimation
  has_many :feedback
end

class Tag < ActiveRecord::Base
  has_many :hashtags
  has_many :tag_tasks, through: :hashtags, source: :task
end

class Hashtag < ActiveRecord::Base
  belongs_to :task
  belongs_to :tag
end