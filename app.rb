#!/usr/bin/env ruby
# Id$ nonnax 2022-03-24 22:00:54 +0800
require_relative 'lib/racker'

class App
  include Rack::R3

  get '/' do
    @req.params
  end
  get '/red' do
    @res.redirect 'http://github.com'
  end
  get '/red/:site' do
    
    @res.redirect "http://#{@req.params[:site]}.com"
  end
  
end

