#!/usr/bin/env ruby
# Id$ nonnax 2022-03-23 17:49:18 +0800
require_relative 'testing'
use Rack::Static,
    urls: %w[/images /js /css],
    root: 'public'

run Franky.get_instance
