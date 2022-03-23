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
  # def service
    # # self.params = @req.query
    # method = @req.request_method.to_sym
    # path_info = @req.path_info
# 
    # named_param = nil
    # block =
      # @routes
        # .find { |pair, _|
          # path, meth = pair
          # pattern, named_param = to_pattern(path)
          # # p [pattern, named_param]
          # pattern.match(path_info)
        # }
        # .then{|route|
          # p [route.class, route]
          # route.last rescue nil
          # # route[0][method] rescue nil
        # }
# #
    # if block
      # # $1 will be the named param value
      # self.params.merge!({ named_param => $1 }) if named_param
      # Franky.get_instance.instance_eval(&block).to_s
    # else
      # "unknown route: #{method} #{@req.path_info}"
    # end
  # end

  def call(env)
    _call(env)
    p params
    p @res.instance_variable_get :@headers
    p @res.instance_variables
    p @req.instance_variables

    body = @routes[
                    [ 
                      @req.path_info, @req.request_method.to_sym 
                    ]
                  ]&.call.to_s
    
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
      # directory. Here the binding is a special Ruby method, basically it represents
      # the context of current object self, and in this case, the FakeSinatra instance.
      # 
      # Objects of class Binding encapsulate the execution context at some
      # particular place in the code and retain this context for future use. The
      # variables, methods, value of self, and possibly an iterator block that can be
      # accessed in this context are all retained. Binding objects can be created
      # usingKernel#binding
      path = File.expand_path("../views/#{view}.erb", __dir__)
      template = ERB.new(File.read(path))

      template.result(binding)
    end 
  end

  private
    def to_pattern(path)
    # '/articles/' => %r{\A/articles/?\z}
    # '/articles/:id' => %r{\A/articles/([^/]+)/?\z}
    # '/restaurants/:id/comments' => %r{\A/restaurants/([^/]+)/comments/?\z}

    # remove trailing slashes then add named capture group
    p path = 
      path
      .gsub(/\/+\z/, '')
      .gsub(/\:([^\/]+)/, '([^/]+)')

    # $1 will be the matched named param key if present
    [%r{\A#{path}/?\z}, $1]
  end

end

include Franky::Helpers
