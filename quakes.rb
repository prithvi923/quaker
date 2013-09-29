Bundler.require

# TODO: Place in separate file potentially
DataMapper.setup(:default, ENV['CLEARDB_DATABASE_URL'] || 'mysql://root@localhost/quaker')
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
  days_ago = Time.now() - 3600*24*days
  if params[:region] then
    places = repository(:default).adapter.select(
      "SELECT p2place AS place, time, p2lat AS lat, p2lon AS lon, p2mag AS mag, AVG(p1mag) AS avg_mag
      FROM (SELECT p1.mag AS p1mag, p1.place AS p1place, p1.lat AS p1lat, p1.lon AS p1lon, p2.mag AS p2mag, p2.place AS p2place, p2.lat AS p2lat, p2.lon AS p2lon, p2.time, (3959 * acos( cos( radians(p1.lat) ) * cos( radians( p2.lat ) ) * cos( radians( p2.lon ) - radians(p1.lon) ) + sin( radians(p1.lat) ) * sin( radians( p2.lat ) ) ) ) AS distance
      FROM places AS p1, places AS p2
      HAVING distance < 25) AS region
      WHERE UNIX_TIMESTAMP(time) >= #{days_ago.to_i}
      GROUP BY p2place
      ORDER BY avg_mag DESC
      LIMIT 0, #{count};"
    )
    places.map! { |place| Hash[place.members.zip(place.values)]}
    places.to_json
  else
    Place.all(:time.gte => days_ago, :order => [:mag.desc], :limit => count).to_json
  end
end