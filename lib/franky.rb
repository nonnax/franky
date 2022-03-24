require 'forwardable'

class Franky
  extend Forwardable
  def_delegators :@res, :status, :write, :headers
  def_delegators :@req, :status, :headers, :params
   
  def self.get_instance
    @instance ||= new
  end
  def intitialize
    @headers = { 'Content-Type' => 'text/html; charset=utf-8' }    
  end
  def _call(env)
    @req=Rack::Request.new env
    @res=Rack::Response.new
    @status=@res.status
    # service
  end
  
  def register(method, path, block)
    @routes ||= {}
    @routes[[path, method]] = block
  end
  
  def routes
    @routes
  end
# 
  def call(env)
    _call(env)
    body = service
    @res.write body
    @res.finish
  end

  def headers(additional_headers)
    @req.add_header additional_headers
  end
  
  def status(code)
    @req.status = code
  end
  
  module Helpers
    %w{ get post patch put delete }.each do |method|
      define_method(method) do |path, &block|
        Franky
          .get_instance
          .register(method.upcase.to_sym, path, block)
      end
    end
  
    def redirect(target, code=302)
      Franky.get_instance.instance_eval do
        status(code)
        headers 'Location' => target
      end
    end


    def erb(view)
      # __dir__ is a special method that always return the current file's 
      # directory.
      path = File.expand_path("../views/#{view}.erb", __dir__)
      layout_path = File.expand_path("../views/layout.erb", __dir__)
      template = ERB.new(File.read(path))
      layout_template = ERB.new(File.read(layout_path))

      out=_render( template)
      _render( layout_template){out}
    end 
  end
  def _render(template)
      # Here the binding is a special Ruby method, basically it represents
      # the context of current object self, and in this case, the FrankenSinatra instance.
      # 
      # Objects of class Binding encapsulate the execution context at some
      # particular place in the code and retain this context for future use. The
      # variables, methods, value of self, and possibly an iterator block that can be
      # accessed in this context are all retained. Binding objects can be created
      # usingKernel#binding  
    template.result(binding)
  end

  private
    def to_pattern(path)
    # returns transformed path pattern and any extra_param_names matched
    # '/articles/' => %r{\A/articles/?\z}
    # '/articles/:id' => %r{\A/articles/([^/]+)/?\z}
    # '/restaurants/:id/comments' => %r{\A/restaurants/([^/]+)/comments/?\z}

    # remove trailing slashes then add named capture group
    extra_param_names=[]
    path = 
      path
      .gsub(/\/+\z/, '')
      .gsub(/:\w+/){|match|
        extra_param_names << match.gsub(':','')
        '([^/]+)'
      }

    [%r{\A#{path}/?\z}, extra_param_names]
  end

  def service
    # self.params = @req.query
    method = @req.request_method.to_sym
    path_info = @req.path_info

    named_param = nil
    block =
      @routes
        .find { |pair, _|
          path, meth = pair
          pattern, named_param = to_pattern(path)
          pattern.match(path_info) # captures collected by Regexp.last_match
        }
        .then{|route| route.last rescue nil }

    if block
      # named_param.zip( Regexp.last_match.captures) to hash
      # 
      unless named_param.empty?
        extra_params = named_param.map(&:to_sym).zip( Regexp.last_match.captures).to_h
        self.params.merge!(extra_params) 
      end
      Franky.get_instance.instance_eval(&block).to_s
    else
      @res.status=404
      "Not Found: #{method} #{@req.path_info}"
    end
  end


end

include Franky::Helpers
