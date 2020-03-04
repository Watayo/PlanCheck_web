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
  uri = URI.parse("https://api.line.me/oauth2/v2.1/token")
  request = Net::HTTP::Post.new(uri)
  request.content_type = "application/x-www-form-urlencoded"
  request.set_form_data(
    "client_id" => @line_key,
    "client_secret" => @line_secret,
    "code" => params[:code],
    "grant_type" => "authorization_code",
    "redirect_uri" => "http://localhost:32788/line_callback",
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
  @user_tasks = current_user.tasks

  erb :userpage
end

get '/task_register' do
  #タスク登録のページを表示
  #最初に時間のコストは定義しておく?
  if current_user.costs.nil?
    @user_costs = none
  else
    @user_costs = current_user.costs
  end
  erb :task_register
end

post '/task_register' do
  #タスク登録
  register_task = current_user.tasks.create(
    name: params[:task_name],
    task_comment: params[:task_comment]
  )
  # ユーザーの持つコストごとにタスクをタグつけ
  user_costs = current_user.costs
  user_costs.each do |user_cost|
    Cost.update(
      task_id: register_task.id
    )

    Estimation.create(
      task_id: register_task.id,
      cost_id: user_cost.id,
      cost_estimation: params[:cost_estimation],
      task_estimation: params[:task_estimation]
    )
  end


  redirect "/userpage"
end

get '/cost_register' do
  # コスト登録のページを表示
  erb :cost_register
end

post '/cost_register' do
  # コスト登録
  current_user.costs.create(
    name: params[:cost_name],
    parameter_name: params[:parameter_name],
    def_explain: params[:def_explain]
  )
  redirect '/userpage'
end