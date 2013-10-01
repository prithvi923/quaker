# Use Rufus to schedule the scraping of new earthquake data

scheduler = Rufus::Scheduler.start_new

# Every 15 minutes, update the DB
scheduler.every '15m' do
  update_db
end

def update_db
  # Hit the USGS API
  data = JSON.parse RestClient.get "http://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/2.5_month.geojson"
  data["features"].each do |feature|
    # Catch errors for those locations that already exist in the DB
    begin
      Place.create({
        :mag => feature['properties']['mag'],
        :place => feature['properties']['place'],
        :time => Time.at(feature['properties']['time']/1000),
        :lon => feature['geometry']['coordinates'][0], 
        :lat => feature['geometry']['coordinates'][1]
      })
    rescue
      # Skip if location already exists
      next
    end
  end
  # Clear Redis; simple check to ensure all cached data is invalidated
  $redis.flushall
end