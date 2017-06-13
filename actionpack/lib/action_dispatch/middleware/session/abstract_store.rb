require "rack/utils"
require "rack/request"
require "rack/session/abstract/id"
require "action_dispatch/middleware/cookies"
require "action_dispatch/request/session"

module ActionDispatch
  module Session
    class SessionRestoreError < StandardError #:nodoc:
      def initialize
        super("Session contains objects whose class definition isn't available.\n" \
          "Remember to require the classes for all objects kept in the session.\n" \
          "(Original exception: #{$!.message} [#{$!.class}])\n")
        set_backtrace $!.backtrace
      end
    end

    module Compatibility
      def initialize(app, options = {})
        options[:key] ||= "_session_id"
        super
      end

      def generate_sid
        sid = SecureRandom.hex(16)
        sid.encode!(Encoding::UTF_8)
        sid
      end

    private

      def initialize_sid # :doc:
        @default_options.delete(:sidbits)
        @default_options.delete(:secure_random)
      end

      def make_request(env)
        ActionDispatch::Request.new env
      end
    end

    module StaleSessionCheck
      def load_session(env)
        stale_session_check! { super }
      end

      def extract_session_id(env)
        stale_session_check! { super }
      end

      def stale_session_check!
        yield
      rescue ArgumentError => argument_error
        if argument_error.message =~ %r{undefined class/module ([\w:]*\w)}
          begin
            # Note that the regexp does not allow $1 to end with a ':'.
            $1.constantize
          rescue LoadError, NameError
            raise ActionDispatch::Session::SessionRestoreError
          end
          retry
        else
          raise
        end
      end
    end

    module SessionObject # :nodoc:
      def prepare_session(req)
        Request::Session.create(self, req, @default_options)
      end

      def prepare_default_session(req)
        Request::Session.create_default(self, req, @default_options)
      end

      # NOTE: Why not do this instead?
      # https://github.com/rack/rack/blob/f2dacc6bb881ed1f588eecf00134abca8e26665e/lib/rack/session/abstract/id.rb#L317-L319
      def session_class
        Request::Session
      end
    end

    class AbstractStore < Rack::Session::Abstract::Persisted
      include Compatibility
      include StaleSessionCheck
      include SessionObject

      private

        def set_cookie(request, session_id, cookie)
          request.cookie_jar[key] = cookie
        end
    end
  end
end
