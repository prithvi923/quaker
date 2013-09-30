scheduler = Rufus::Scheduler.start_new

scheduler.every '15m' do
  update_db
end

def update_db
  data = JSON.parse RestClient.get "http://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/2.5_month.geojson"
  data["features"].each do |feature|
    begin
      Place.create({
        :mag => feature['properties']['mag'],
        :place => feature['properties']['place'],
        :time => Time.at(feature['properties']['time']/1000),
        :lon => feature['geometry']['coordinates'][0], 
        :lat => feature['geometry']['coordinates'][1]
      })
    rescue
      next
    end
  end
  $redis.flushall
end