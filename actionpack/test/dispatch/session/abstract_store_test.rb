require "abstract_unit"
require "action_dispatch/middleware/session/abstract_store"

module ActionDispatch
  module Session
    class AbstractStoreTest < ActiveSupport::TestCase
      class MemoryStore < AbstractStore
        def initialize(app)
          @sessions = {}
          super
        end

        def find_session(req, sid)
          sid ||= 1
          # Same here
          # session = @sessions[sid] ||= {}
          session = @sessions[sid] ||= prepare_session(req)
          [sid, session]
        end

        def write_session(req, sid, session, options)
          @sessions[sid] = session
        end
      end

      def test_session_is_set
        env = {}
        as = MemoryStore.new app
        as.call(env)

        assert @env
        assert Request::Session.find ActionDispatch::Request.new @env
      end

      def test_new_session_object_is_merged_with_old
        env = {}
        as = MemoryStore.new app
        as.call(env)

        assert @env
        session = Request::Session.find ActionDispatch::Request.new @env
        session["foo"] = "bar"

        as.call(@env)
        session1 = Request::Session.find ActionDispatch::Request.new @env

        assert_not_equal session, session1
        assert_equal session.to_hash, session1.to_hash
      end

      private
        def app(&block)
          @env = nil
          lambda { |env| @env = env }
        end
    end
  end
end
