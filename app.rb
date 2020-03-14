require 'bundler/setup'
Bundler.require
require 'sinatra/reloader' if development?
require 'sinatra/activerecord'
require 'oauth2'
require 'jwt'
require './models'
require 'json'
require 'line/bot'

enable :sessions


def client
  @client ||= Line::Bot::Client.new { |config|
    config.channel_id = ENV["LINE_CHANNEL_ID"]
    config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
    config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
  }
end

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
  ngrok = "https://47841a9a.ngrok.io/line_callback"
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

  p register_task.save
  if register_task.save
       # 真
    register_task.create_task_scale.create_estimation(
      your_estimation: params[:scale_estimation].to_i,
      estimation_comment: params[:period_comment]
    )

    register_task.create_task_period.create_estimation(
      your_estimation: params[:period_estimation].to_i,
      estimation_comment: params[:period_comment]
    )

    register_task.create_task_manhour.create_estimation(
      your_estimation: params[:manhour_estimation].to_i,
      estimation_comment: params[:manhour_comment]
    )

    register_task.create_task_experience.create_estimation(
      your_estimation: params[:experience_estimation].to_i,
      estimation_comment: params[:experience_comment]
    )

    register_task.task_scale.create_feedback()
    register_task.task_period.create_feedback()
    register_task.task_manhour.create_feedback()
    register_task.task_experience.create_feedback()

    redirect "/userpage"
  else
    erb :task_register
  end
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


  @task.task_scale.create_feedback(
    fact: params[:scale_feedback].to_i,
    feedback_comment: params[:scale_comment]
  )
  @task.task_period.create_feedback(
    fact: params[:period_feedback].to_i,
    feedback_comment: params[:period_comment]
  )
  @task.task_manhour.create_feedback(
    fact: params[:manhour_feedback].to_i,
    feedback_comment: params[:manhour_comment]
  )
  @task.task_experience.create_feedback(
    fact: params[:experience_feedback].to_i,
    feedback_comment: params[:experience_comment]
  )

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

  p @scale_val


  @scale_fb = @task.task_scale.feedback
  @period_fb = @task.task_period.feedback
  @manhour_fb = @task.task_manhour.feedback
  @experience_fb = @task.task_experience.feedback

  p @scale_fb
  erb :task_log
end

post '/task_delete_log/:id' do
  delete_task = Task.find(params[:id])
  delete_task.destroy
  redirect '/user_statistics'
end

# --------------------LINE-----------------------

post '/callback' do
  body = request.body.read

  signature = request.env['HTTP_X_LINE_SIGNATURE']
  unless client.validate_signature(body, signature)
    error 400 do 'Bad Request' end
  end

  parsed_json = JSON.parse(body)

  events = client.parse_events_from(body)

  # ユーザー情報を取得する。
  # ID = U146840584a28358f1dfc87986eb6b64b　（確認用）
  user_id = parsed_json["events"][0]["source"]["userId"]

  user_response = client.get_profile(user_id)
  case user_response
  when Net::HTTPSuccess then
    contact = JSON.parse(user_response.body)
    p contact['displayName']
    p contact['pictureUrl']
    p contact['statusMessage']
  else
    p "#{response.code} #{response.body}"
  end

  # ある文字列を取得したときに、そのユーザーの情報からログインしてタスク登録の画面まで飛ばす。

  user = User.find_or_create_by(sub: user_id)
  if user.persisted?
    session[:user] = user.id
  end

  user_tasks = current_user.tasks.where(feedback_done: false)

  #
  events.each do |event|
    case event
    when Line::Bot::Event::Message
      case event.type
      when Line::Bot::Event::MessageType::Text
        if event.message['text'] =~ /リスト/
          if user_tasks.present?
            user_tasks.each do |task|
              message = {
                type: 'text',
                text: "タスク名：#{task.name}\r#{task.due_date}締め切りです!\r"
              }
              client.reply_message(event['replyToken'], message)
            end
          else
            message = {
                type: 'text',
                text: "実行中のタスクは今ないよ！"
              }
              client.reply_message(event['replyToken'], message)
          end
        elsif event.message['text'] =~ /タスク登録/
          message = {
            type: 'text',
            text: "タスク登録しましょ〜〜！\rhttps://plancheck-webapp.com/"

          }
          client.reply_message(event['replyToken'], message)
        elsif event.message['text'] =~ /フィードバック/
          message = {
            type: 'text',
            text: "タスク完了したの？\rそれなら覚えているうちに見積もりを反省しよう！\rhttps://plancheck-webapp.com/"
          }
          client.reply_message(event['replyToken'], message)
        elsif  event.message['text'] =~ /今まで/
          message = {
            type: 'text',
            text: "え？”今まで”の反省がみたいのかな？それなら！\https://plancheck-webapp.com/"
          }
          client.reply_message(event['replyToken'], message)
        else
          message = {
            type: 'text',
            text: "Ooops!!!!!\rタスク登録、とか送信してみて！"
          }
          client.reply_message(event['replyToken'], message)
        end
      when Line::Bot::Event::MessageType::Image, Line::Bot::Event::MessageType::Video
        response = client.get_message_content(event.message['id'])

        tf = Tempfile.open("content")
        tf.write(response.body)
      end
    end
  end
  "OK!"
end
