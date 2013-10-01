class MyQuaker < Sinatra::Application
  get '/quakes' do
    content_type :json

    badParams = false
    res = Hash.new

    begin
      count = params[:count] ? Integer(params[:count]) : 10
    rescue ArgumentError
      count = 10
      badParams = true
    end

    begin
      days = params[:days] ? Integer(params[:days]) : 10
    rescue ArgumentError
      days = 10
      badParams = true
    ensure
      days_ago = Time.now() - 3600*24*days
    end

    begin
      wantsRegion = params[:region] ? to_boolean(params[:region]) : false
    rescue ArgumentError
      wantsRegion = false
      badParams = true
    end

    res["status"] = badParams ? "error: bad parameter(s) given; defaults used" : "ok"
    hash = "c" + count.to_s + "d" + days.to_s + wantsRegion.to_s

    if $redis.get(hash) then
      res["payload"] = JSON.parse $redis.get(hash)
      return res.to_json
    end

    payload = get_payload(count, days_ago, wantsRegion)

    $redis.set(hash, payload.to_json)
    res["payload"] = payload
    return res.to_json
  end

  def get_payload(count, days_ago, wantsRegion)
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
      places.each { |place| place.delete(:avg_mag) }
    else
      Place.all(:time.gte => days_ago, :order => [:mag.desc], :limit => count) 
    end
  end

  def to_boolean(str)
    return true if str.downcase == "true"
    return false if str.downcase == "false"
    raise ArgumentError
  end
end