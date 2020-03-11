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
  erb :index, layout: nil
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

  # パラメーターごとにタスクを登録したい
  register_task.build_task_scale.build_estimation(
    estimation: params[:scale_estimation],
    estimation_comment: params[:scale_comment]
  ).save

  register_task.build_task_period.build_estimation(
    estimation: params[:period_estimation],
    estimation_comment: params[:period_comment]
  ).save

  register_task.build_task_manhour.build_estimation(
    estimation: params[:manhour_estimation],
    estimation_comment: params[:manhour_comment]
  ).save

  register_task.build_task_experience.build_estimation(
    estimation: params[:experience_estimation],
    estimation_comment: params[:experience_comment]
  ).save

  register_task.build_task_scale.build_feedback().save
  register_task.build_task_period.build_feedback().save
  register_task.build_task_manhour.build_feedback().save
  register_task.build_task_experience.build_feedback().save

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

  @scale_val = @task.task_scale.estimation
  @period_val = @task.task_period.estimation
  @manhour_val = @task.task_manhour.estimation
  @experience_val = @task.task_experience.estimation

  erb :task_feedback
end

post '/feedback_register' do
  @task = Task.find(params[:task_id])


  @task.build_task_scale.build_feedback(
    fact: params[:scale_feedback].to_i,
    feedback_comment: params[:scale_comment]
  ).save
  @task.build_task_period.build_feedback(
    fact: params[:period_feedback].to_i,
    feedback_comment: params[:period_comment]
  ).save
  @task.build_task_manhour.build_feedback(
    fact: params[:manhour_feedback].to_i,
    feedback_comment: params[:manhour_comment]
  ).save
  @task.build_task_experience.build_feedback(
    fact: params[:experience_feedback].to_i,
    feedback_comment: params[:experience_comment]
  ).save

  @task.feedback_done = true
  @task.save


  redirect '/userpage'
end

get '/user_statistics' do
  # ユーザーが定義したコストごとに今までの統計を表示する。
  @user_tasks = current_user.tasks

  @task_scale_sum = Array.new([0, 0, 0, 0])
  @user_tasks.each { |task|
    if task.task_scale.feedback.fact == 1
      @task_scale_sum[0] += 1
    elsif task.task_scale.feedback.fact == 2
      @task_scale_sum[1] += 1
    elsif task.task_scale.feedback.fact == 3
      @task_scale_sum[2] += 1
    else
      @task_scale_sum[3] += 1
    end
  }

  @task_period_sum = Array.new([0, 0, 0, 0])
  @user_tasks.each { |task|
    if task.task_period.feedback.fact == 1
      @task_period_sum[0] += 1
    elsif task.task_period.feedback.fact == 2
      @task_period_sum[1] += 1
    elsif task.task_period.feedback.fact == 3
      @task_period_sum[2] += 1
    else
      @task_period_sum[3] += 1
    end
  }

  @task_manhour_sum = Array.new([0, 0, 0, 0])
  @user_tasks.each { |task|
    if task.task_manhour.feedback.fact == 1
      @task_manhour_sum[0] += 1
    elsif task.task_manhour.feedback.fact == 2
      @task_manhour_sum[1] += 1
    elsif task.task_manhour.feedback.fact == 3
      @task_manhour_sum[2] += 1
    else
      @task_manhour_sum[3] += 1
    end
  }

  @task_experience_sum = Array.new([0, 0, 0, 0])
  @user_tasks.each { |task|
    if task.task_experience.feedback.fact == 1
      @task_experience_sum[0] += 1
    elsif task.task_experience.feedback.fact == 2
      @task_experience_sum[1] += 1
    elsif task.task_manhour.feedback.fact == 3
      @task_experience_sum[2] += 1
    else
      @task_experience_sum[3] += 1
    end
  }

  erb :user_statistics
end

get '/task_log/:id' do
  @task = Task.find(params[:id])

  @scale_val = @task.task_scale.estimation
  @period_val = @task.task_period.estimation
  @manhour_val = @task.task_manhour.estimation
  @experience_val = @task.task_experience.estimation

  @scale_fb = @task.task_scale.feedback
  @period_fb = @task.task_period.feedback
  @manhour_fb = @task.task_manhour.feedback
  @experience_fb = @task.task_experience.feedback

  erb :task_log
end
