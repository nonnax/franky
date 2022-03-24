# frozen_string_literal: true

require 'forwardable'

class Franky
  extend Forwardable
  def_delegators :@res, :status, :write, :headers, :redirect
  def_delegators :@req, :status, :headers, :params

  def self.get_instance
    @instance ||= new
  end

  def intitialize
    @headers = { 'Content-Type' => 'text/html; charset=utf-8' }
  end

  def _call(env)
    @req = Rack::Request.new env
    @res = Rack::Response.new
  end

  def register(method, path, block)
    route = {
      path: path,
      compiled_path: nil,
      extra_params: nil,
      block: block
    }

    compile_path(path).then do |compiled_path, extra_params|
      route[:compiled_path] = compiled_path
      route[:extra_params] = extra_params
      self.routes[method] << route
    end
  end

  def routes
    @routes ||= Hash.new { |hash, key| hash[key] = [] }
  end

  def call(env)
    _call(env)
    body = service
    @res.write body
    @res.finish
  end

  def status(code)
    @res.status=code
  end

  module Helpers
    # public methods   
    %w[get post patch put delete].each do |method|
      define_method(method) do |path, &block|
        Franky
          .get_instance
          .register(method.upcase.to_sym, path, block)
      end
    end

    def erb(view)
      render(view)
    end
  end

  private

  def render(view, layout: :layout)
    # __dir__ is a special method that always return the current file's directory.
    templates = []
    templates << File.expand_path("../views/#{view}.erb", __dir__)
    templates << File.expand_path("../views/#{layout}.erb", __dir__)
    
    templates.inject("") do |doc, f|
      _render(f){doc}
    end
  end
  
  def _render(f)
    # Here the binding is a special Ruby method, basically it represents
    # the context of current object self, and in this case, the Franky instance.
    #
    ERB.new( File.read(f) ).result( binding )
  end

  def compile_path(path)
    # returns transformed path pattern and any extra_param_names matched
    # '/articles/' => %r{\A/articles/?\z}
    # '/articles/:id' => %r{\A/articles/([^/]+)/?\z}
    # '/restaurants/:id/comments' => %r{\A/restaurants/([^/]+)/comments/?\z}

    # remove trailing slashes then add named capture group
    extra_param_names = []
    path =
      path
      .gsub(%r{/+\z}, '')
      .gsub(/:\w+/) do |match|
        extra_param_names << match.gsub(':', '').to_sym
        '([^/]+)'
      end

    [%r{\A#{path}/?\z}, extra_param_names]
  end

  def service
    @routes[@req.request_method.to_sym]
      .detect { |r| r[:compiled_path].match(@req.path_info) } # captures collected by Regexp.last_match
      .then do |r|
        if r
           r[:extra_params].zip( Regexp.last_match.captures )
           .to_h
           .then{|extra_params| self.params.merge!(extra_params) }
        end
        r
      end
      .then do |r|
        return Franky.get_instance.instance_eval(&r[:block]).to_s if r
      end
    # default
    _not_found
  end
  def _not_found
     @res.status=404
     not_found
  end
  def not_found
    # to be overriden
    'Not Found'
  end
end

# public methods get, post, etc...
include Franky::Helpers
