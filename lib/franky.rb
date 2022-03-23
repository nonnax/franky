class Franky
  def self.get_instance
    @instance ||= new
  end

  def register(method, path, block)
    @routes ||= {}
    @routes[path] ||= {}
    @routes[path][method] = block
  end
  
  def routes
    @routes
  end

  # def service(req, res)
    # @params = req.query
    # method = req.request_method.to_sym
# 
    # named_param = nil
    # block =
      # @routes
        # .find { |path, _|
          # pattern, named_param = to_pattern(path)
          # pattern.match(req.path)
        # }
        # .then{|route| route[1][method] rescue nil}
# 
    # if block
      # # $1 will be the named param value
      # @params.merge!({ named_param => $1 }) if named_param
      # res.body = Franky.get_instance.instance_eval(&block).to_s
    # else
      # res.body = "unknown route: #{method} #{req.path}"
    # end
  # end

  def call(env)
    # Lookup path in routes hash.
    @status = 200
    req_path = env['PATH_INFO']
    req_method = env['REQUEST_METHOD'].to_sym
        
    @routes[req_path][req_method]
    body = @routes[req_path][req_method].call.to_s
    [@status, {'Content-Type' => 'text/html'}.merge(@headers || {}), [body]]
  end

  def headers(additional_headers)
    @headers = additional_headers
  end
  
  def status(code)
    @status = code
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

end

include Franky::Helpers
