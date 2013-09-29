Bundler.require

configure do
  DataMapper.setup(:default, ENV['CLEARDB_DATABASE_URL'] || 'mysql://root@localhost/quaker')
end

# TODO: Create separate model file
class Place
  include DataMapper::Resource

  property :mag,     Float
  property :place,   String
  property :time,    Time, :key => true
  property :lat,     Float, :key => true
  property :lon,     Float, :key => true

end

DataMapper.auto_upgrade!

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
    begin
      Place.create({
          :mag => feature['properties']['mag'],
          :place => feature['properties']['place'],
          :time => Time.at(feature['properties']['time']/1000),
          :lon => feature['geometry']['coordinates'][0], 
          :lat => feature['geometry']['coordinates'][1]
        })
    rescue
      continue
    end
  end
end

get '/' do
  "Hello, world!"
end

get '/quakes' do
  content_type :json

  count = 10
  days = 10

  if params[:count] then
    count = params[:count].to_i
  end
  if params[:days] then
    days = params[:days].to_i
  end

  Place.all(:time.gte => Time.now() - 3600*24*days, :order => [:mag.desc], :limit => count).to_json
end