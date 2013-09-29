Bundler.require
require_relative 'models/init'
require_relative 'helpers/init'

get '/' do
  "Hello, world!"
end

get '/quakes' do
  content_type :json

  count = 10
  days = 10
  wantsRegion = false

  if params[:count] then
    count = params[:count].to_i
  end
  if params[:days] then
    days = params[:days].to_i
  end
  if params[:region] == "true" || params[:region] == "false" then
    wantsRegion = params[:region]
  end
  days_ago = Time.now() - 3600*24*days

  hash = count.to_s + days.to_s + wantsRegion.to_s

  if $redis.get(hash) then
    return $redis.get(hash)
  end

  if wantsRegion then
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
    res = places.to_json
  else
    res = Place.all(:time.gte => days_ago, :order => [:mag.desc], :limit => count).to_json
  end

  $redis.set(hash, res)
  return res
end