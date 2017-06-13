require "action_dispatch/middleware/session/abstract_store"

module ActionDispatch
  module Session
    # A session store that uses an ActiveSupport::Cache::Store to store the sessions. This store is most useful
    # if you don't store critical data in your sessions and you don't need them to live for extended periods
    # of time.
    #
    # ==== Options
    # * <tt>cache</tt>         - The cache to use. If it is not specified, <tt>Rails.cache</tt> will be used.
    # * <tt>expire_after</tt>  - The length of time a session will be stored before automatically expiring.
    #   By default, the <tt>:expires_in</tt> option of the cache is used.
    class CacheStore < AbstractStore
      def initialize(app, options = {})
        @cache = options[:cache] || Rails.cache
        options[:expire_after] ||= @cache.options[:expires_in]
        super
      end

      # Get a session from the cache.
      def find_session(req, sid)
        unless sid && (session = @cache.read(cache_key(sid)))
          sid = generate_sid

          # Here?
          # session = {}

          # session = session_class.create(store, req, default_options)
          # Or even better `prepare_session(req)`
          # No params to make it happen...
          # Req param were badly named?
          session = prepare_session(req)

          # Maybe what we need is for the class that inherit from AbstractStore to define "new_session"
          # Should "failing to load a session by it's sid" simply raise?
        end
        [sid, session]
      end

      # Set a session in the cache.
      def write_session(req, sid, session, options)
        key = cache_key(sid)
        if session
          @cache.write(key, session, expires_in: options[:expire_after])
        else
          @cache.delete(key)
        end
        sid
      end

      # Remove a session from the cache.
      def delete_session(env, sid, options)
        @cache.delete(cache_key(sid))
        generate_sid
      end

      private
        # Turn the session id into a cache key.
        def cache_key(sid)
          "_session_id:#{sid}"
        end
    end
  end
end
