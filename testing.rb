#!/usr/bin/env ruby
# Id$ nonnax 2022-03-23 17:48:56 +0800
require_relative 'lib/franky'

get '/' do
  'hello'
end

get '/print' do
  erb :index
end

get '/time' do
  @time = Time.now
  erb :time
end

get '/temp-redirect' do
  redirect 'http://google.com'
end
