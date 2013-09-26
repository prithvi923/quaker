Bundler.require

# TODO: Create a YAML config file
configure do
  if ENV['MONGOLAB_URI'] then
    MongoMapper.setup({'production' => {'uri' => ENV['MONGOLAB_URI']}}, 'production')
  else
    MongoMapper.setup({'development' => {'uri' => 'mongodb://localhost/quaker'}}, 'development')
  end
end

# TODO: Create separate model file
class Place
  include MongoMapper::Document

  key :mag,   Float
  key :place, String
  key :time, Time
  key :location, Array

  ensure_index [[:location, '2dsphere']]
  ensure_index [[:location, 1], [:time, -1]], :unique => true

end

# TODO: Place in separate file potentially
scheduler = Rufus::Scheduler.start_new
scheduler.every '15m' do
  update_db
end

def update_db
  data = RestClient.get "http://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/2.5_month.geojson"
  data = JSON.parse data
  features = data["features"]
  features.each do |feature|
    Place.create({
        :mag => feature['properties']['mag'],
        :place => feature['properties']['place'],
        :time => Time.at(feature['properties']['time']/1000),
        :location => [feature['geometry']['coordinates'][0], feature['geometry']['coordinates'][1]]
      })
  end
end

get '/' do
  "Hello, world!"
end