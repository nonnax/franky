# frozen_string_literal: true

module Rack
  module R3
    METHODS = %i[GET POST PUT DELETE PATCH HEAD OPTIONS].freeze

    def self.included(base)      
      base.instance_eval do
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
      end
      
      base.class_eval do
        @@routes = Hash.new([])

        def self.routes
          @@routes
        end

        METHODS.each do |verb|
          define_singleton_method(verb.downcase) do |path, &block|
            route = { path: path, compiled_path: nil, extra_params: nil, block: block}

            compile_path(path).then do |compiled_path, extra_params|
              route[:compiled_path] = compiled_path
              route[:extra_params] = extra_params
              @@routes[verb] << route
            end
          end
        end
      end
    end

    def service(env)
      self.class.routes[@req.request_method.to_sym]
        .detect { |r| r[:compiled_path].match(@req.path_info) } # captures collected by Regexp.last_match
        .then do |r|
          if r
            r[:extra_params].zip(Regexp.last_match.captures)
                            .to_h
                            .then { |extra_params| @req.params.merge!(extra_params) }
          end
          r
        end
        .then do |r|
          return instance_eval(&r[:block]).to_s rescue nil
        end
    end

    def _call(env)
      @env = env
      @req = Rack::Request.new @env
      @res = Rack::Response.new
    
      body=service(env)

      @res.headers.merge!('Content-type' => 'text/html; charset=utf-8') if @res.headers.empty?
      @res.write body
      
      return @res.finish if body
      
      not_found
      
    end
    
    def call(env)
      dup._call(env)
    end

    def not_found
      [404,
       { 'Content-type' => 'text/plain; charset=utf-8' },
       ['Not Found']]
    end
  end
end

# include Rack::R3
