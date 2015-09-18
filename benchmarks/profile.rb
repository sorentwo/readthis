require 'bundler'

Bundler.setup

require 'fileutils'
require 'stackprof'
require 'readthis'

readthis = Readthis::Cache.new

FileUtils.mkdir_p('tmp')
readthis.clear

('a'..'z').each { |key| readthis.write(key, key * 1024) }

StackProf.run(mode: :object, interval: 500, out: "tmp/stackprof-object.dump") do
  1000.times do
    readthis.read_multi(*('a'..'z'))
  end
end
