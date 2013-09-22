Bundler.require

# TODO: Create a YAML config file
configure do
  MongoMapper.setup({'production' => {'uri' => ENV['MONGOLAB_URI']}}, 'production')
  MongoMapper.setup({'development' => {'uri' => 'mongodb://localhost/quaker'}}, 'development')
end

get '/' do
  "Hello World!"
end