require 'bundler/setup'
Bundler.require
require 'sinatra/reloader' if development?
require 'sinatra/activerecord'
require 'oauth2'
require 'jwt'
require './models'

enable :sessions

before do
  Dotenv.load
  @line_key = ENV['LINE_ACCESS_KEY']
  @line_secret = ENV['LINE_ACCESS_SECRET']
end

before '/userpage' do
  if current_user.nil?
    redirect '/'
  end
end

helpers do
  def current_user
    User.find_by(id: session[:user])
  end
end

get '/' do
  # このサイトの紹介のページにするつもり
  # 必要な情報
  # 様々なユーザーの統計情報、(カレンダー)
  erb :index
end

get '/signup' do
  erb :signup
end

get '/login' do
  erb :login
end

# LINE AOuth認証
get '/line_callback' do
  local = "http://localhost:32788/line_callback"
  heroku = "https://plancheck-webapp.com/line_callback"
  uri = URI.parse("https://api.line.me/oauth2/v2.1/token")
  request = Net::HTTP::Post.new(uri)
  request.content_type = "application/x-www-form-urlencoded"
  request.set_form_data(
    "client_id" => @line_key,
    "client_secret" => @line_secret,
    "code" => params[:code],
    "grant_type" => "authorization_code",
    "redirect_uri" => heroku
  )

  req_options = {
    use_ssl: uri.scheme == "https"
  }

  response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
    http.request(request)
  end

  # base64urlでエンコードされたIDトークンからJWTの仕様に基づいてデコードする
  decoded_jwt = JWT.decode(JSON.parse(response.body)["id_token"], @line_secret, false)
  # 返されたJSON形式
  # {
  #   {
  #     "sub" : userID,
  #     "name" : user_name
  #     ...
  #   },
  #   {
  #     "typ" : "JWT"
  #   }
  # }
  user = User.find_or_create_by(sub: decoded_jwt[0]['sub'])
  user.update_attributes(
    name: decoded_jwt[0]["name"],
    img: decoded_jwt[0]["picture"]
  )
  if user.persisted?
    session[:user] = user.id
  end
  redirect '/userpage'
end

get '/signout' do
  session[:user] = nil
  redirect '/'
end

get '/userpage' do
  # current_userの統計情報が乗る
  # タスク登録とコスト登録のボタン
  @user_tasks = current_user.tasks.where(feedback_done: false)
  erb :userpage
end

get '/task_register' do
  #タスク登録のページを表示

  erb :task_register
end

post '/task_register' do
  #タスク登録
  register_task = current_user.tasks.create(
    name: params[:task_name],
    due_date: params[:due_date],
    task_comment: params[:task_comment],
    hashtag: params[:hashtag]
  )

  scale = TaskScale.create(task_id: register_task.id)
  period = TaskPeriod.create(task_id: register_task.id)
  manhour = TaskManhour.create(task_id: register_task.id)
  experience = TaskExperience.create(task_id: register_task.id)

# パラメーターごとにタスクを登録したい
  scale.estimations.create(
    estimation: params[:scale_estimation],
    estimation_comment: params[:scale_comment]
  )
  period.estimations.create(
    estimation: params[:period_estimation],
    estimation_comment: params[:period_comment]
  )
  manhour.estimations.create(
    estimation: params[:manhour_estimation],
    estimation_comment: params[:manhour_comment]
  )
  experience.estimations.create(
    estimation: params[:experience_estimation],
    estimation_comment: params[:experience_comment]
  )

  redirect "/userpage"
end

post '/task_delete/:id' do
  delete_task = Task.find(params[:id])
  delete_task.destroy
  redirect '/userpage'
end

post '/task_completed/:id' do
  done_task = Task.find(params[:id])
  done_task.completed = !done_task.completed
  done_task.save
  redirect '/userpage'
end

get '/task_feedback/:id' do
  @task = Task.find(params[:id])

  scale = TaskScale.find_by(task_id: @task)
  period = TaskPeriod.find_by(task_id: @task)
  manhour = TaskManhour.find_by(task_id: @task)
  experience = TaskExperience.find_by(task_id: @task)

  @scale_val = Estimation.find_by(task_scale_id: scale.id)
  @period_val = Estimation.find_by(task_period_id: period.id)
  @manhour_val = Estimation.find_by(task_manhour_id: manhour.id)
  @experience_val = Estimation.find_by(task_experience_id: experience.id)

  erb :task_feedback
end

post '/feedback_register' do
  @task = Task.find(params[:task_id])

  scale = TaskScale.find_by(task_id: @task.id)
  period = TaskPeriod.find_by(task_id: @task.id)
  manhour = TaskManhour.find_by(task_id: @task.id)
  experience = TaskExperience.find_by(task_id: @task.id)

  scale.feedbacks.create(
    fact: params[:scale_feeback],
    feedback_comment: params[:scale_comment]
  )
  period.feedbacks.create(
    fact: params[:period_feedback],
    feedback_comment: params[:period_comment]
  )
  manhour.feedbacks.create(
    fact: params[:manhour_feedback],
    feedback_comment: params[:manhour_comment]
  )
  experience.feedbacks.create(
    fact: params[:experience_feedback],
    feedback_comment: params[:experience_comment]
  )

  @task.feedback_done = true
  @task.save

  redirect '/userpage'
end

get '/user_statistics' do
  # ユーザーが定義したコストごとに今までの統計を表示する。
  @user_tasks = current_user.tasks

  erb :user_statistics
end

get '/task_log/:id' do
  @task = Task.find(params[:id])

  scale = TaskScale.find_by(task_id: @task.id)
  period = TaskPeriod.find_by(task_id: @task.id)
  manhour = TaskManhour.find_by(task_id: @task.id)
  experience = TaskExperience.find_by(task_id: @task.id)

  @scale_val = Estimation.find_by(task_scale_id: scale.id)
  @period_val = Estimation.find_by(task_period_id: period.id)
  @manhour_val = Estimation.find_by(task_manhour_id: manhour.id)
  @experience_val = Estimation.find_by(task_experience_id: experience.id)

  @scale_fb = Feedback.find_by(task_scale_id: scale.id)
  @period_fb = Feedback.find_by(task_period_id: scale.id)
  @manhour_fb = Feedback.find_by(task_manhour_id: scale.id)
  @experience_fb = Feedback.find_by(task_experience_id: scale.id)

  erb :task_log
end
