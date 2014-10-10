require 'thin'
module Plank
  class Server
    PORT = "9292"
    HOST = "localhost"
    ENVIRONMENT = "development"

    def self.start
      new(ARGV).start
    end

    def initialize(args)
      @options = default_options
      @options[:config] = args[0]
      @app = build_app
    end

    def start
      server.run @app, @options
    end
    
    private

    def default_options
      {
        environment: ENVIRONMENT,
        Port: PORT,
        Host: HOST,
      }
    end

    def build_app
      Plank::Builder.parse_file(@options[:config])
    end

    def server
      @server ||= Plank::Handler.default
    end
  end
  class Builder
    def self.parse_file(file)
      cfg_file = File.read(file)
      new_from_string(cfg_file)
    end
    
    def self.new_from_string(builder_script)
      eval "Plank::Builder.new {\n" + builder_script + "\n}.to_app"
    end

    def initialize(&block)
      instance_eval(&block) if block_given?
    end

    def run(app)
      @run = app
    end

    def to_app
      @run
    end
  end

  module Handler
    def self.default
      Plank::Handler::Thin
    end
    class Thin
      def self.run(app, options={})
        host = options[:Host]
        port = options[:Port]
        args = [host, port, app, options]
        server = ::Thin::Server.new(*args)
        server.start
      end
    end
  end
end
