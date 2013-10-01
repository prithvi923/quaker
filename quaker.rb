Bundler.require
require_relative 'models/init'
require_relative 'helpers/init'
require_relative 'routes/init'

class MyQuaker < Sinatra::Application
  configure do
    DataMapper.setup(:default, ENV['CLEARDB_DATABASE_URL'] || 'mysql://root@localhost/quaker')
    DataMapper.auto_upgrade!

    uri = URI.parse(ENV['REDISCLOUD_URL'] || 'http://localhost:6379/')
    $redis = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)
    $redis.flushall
  end
end