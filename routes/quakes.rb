class MyQuaker < Sinatra::Application
  get '/quakes' do
    content_type :json

    @badParams = false
    res = Hash.new

    # Parse params, setting to default values if errors are thrown
    count = parse_count(params[:count])
    days = parse_days(params[:days])
    wantsRegion = parse_region(params[:region])

    # Set status of response according to @badParams
    res["status"] = @badParams ? "error: bad parameter(s) given; defaults used" : "ok"

    # Form hash from params and then check $redis to see if in cache
    hash = "c" + count.to_s + "d" + days.to_s + wantsRegion.to_s
    if $redis.get(hash) then
      res["payload"] = JSON.parse $redis.get(hash)
      return res.to_json
    end

    # Otherwise, query MySQL for payload
    payload = get_payload(count, days, wantsRegion)

    # Store in cache
    $redis.set(hash, payload.to_json)

    # Return response
    res["payload"] = payload
    return res.to_json
  end

  # Helper function to parse count parameter
  def parse_count(count)
    begin
      count ? Integer(count) : 10
    rescue ArgumentError
      @badParams = true
      10
    end
  end

  # Helper function to parse days parameter
  def parse_days(days)
    begin
      params[:days] ? Integer(params[:days]) : 10
    rescue ArgumentError
      @badParams = true
      10
    end
  end

  # Helper function to parse region parameter
  def parse_region(region)
    begin
      params[:region] ? to_boolean(params[:region]) : false
    rescue ArgumentError
      @badParams = true
      false
    end
  end

  def get_payload(count, days, wantsRegion)
    # Convert time to Unix Timestamp
    days = Time.now() - 3600*24*days
    # If region is true, then use custom SQL query that returns #{count} places that all experienced earthquakes within #{days} ago, using magnitudes within 25 miles that also occurred #{days} ago
    if wantsRegion then
      places = repository(:default).adapter.select(
        "SELECT p2place AS place, time, p2lat AS lat, p2lon AS lon, p2mag AS mag, AVG(p1mag) AS avg_mag
        FROM (SELECT p1.mag AS p1mag, p1.place AS p1place, p1.lat AS p1lat, p1.lon AS p1lon, p2.mag AS p2mag, p2.place AS p2place, p2.lat AS p2lat, p2.lon AS p2lon, p2.time, (3959 * acos( cos( radians(p1.lat) ) * cos( radians( p2.lat ) ) * cos( radians( p2.lon ) - radians(p1.lon) ) + sin( radians(p1.lat) ) * sin( radians( p2.lat ) ) ) ) AS distance
        FROM places AS p1, places AS p2
        HAVING distance < 25) AS region
        WHERE UNIX_TIMESTAMP(time) >= #{days.to_i}
        GROUP BY p2place
        ORDER BY avg_mag DESC
        LIMIT 0, #{count};"
      )
      # Transform structs into hashes
      places.map! { |place| Hash[place.members.zip(place.values)]}
      # Remove avg_mag from hashes
      places.each { |place| place.delete(:avg_mag) }
    else
      # Otherwise, use DataMapper to query the Places
      Place.all(:time.gte => days, :order => [:mag.desc], :limit => count) 
    end
  end

  # Helper function to convert between string and boolean
  def to_boolean(str)
    return true if str.downcase == "true"
    return false if str.downcase == "false"
    raise ArgumentError
  end
end