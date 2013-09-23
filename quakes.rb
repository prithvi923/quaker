Bundler.require

# TODO: Create a YAML config file
configure do
  if ENV['MONGOLAB_URI'] then
    MongoMapper.setup({'production' => {'uri' => ENV['MONGOLAB_URI']}}, 'production')
  else
    MongoMapper.setup({'development' => {'uri' => 'mongodb://localhost/quaker'}}, 'development')
  end
end

get '/' do
  "Hello World!"
end