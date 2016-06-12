module Readthis
  class Scripts
    attr_reader :loaded, :pool

    def initialize(pool)
      @loaded = {}
      @pool   = pool
    end

    def sha(command)
      loaded[command] ||= load_script!(command)
    end

    private

    def load_script!(command)
      path = File.join('script', "#{command}.lua")

      pool.with do |store|
        File.open(path) do |file|
          loaded[command] = store.script(:load, file.read)
        end
      end
    end
  end
end
