ruby '2.6.2'
source "https://rubygems.org"

gem 'rubocop'
gem 'ruby-debug-ide'
gem 'debase'
gem 'rcodetools'
gem 'fastri'

gem 'sinatra'
gem 'sinatra-contrib'

gem 'rake'
gem 'activerecord' , '5.2.3'
gem 'sinatra-activerecord'
gem 'bcrypt'

gem 'dotenv' #.gitignoreを使うために入れる

gem 'jwt'

group :development do
  gem 'sqlite3' , '1.4.1'
  gem 'pry'
  gem 'rubocop-performance'
end

group :production do
  gem 'pg' , '~> 0.21.0'
end


#line-oauth認証
gem 'oauth2'