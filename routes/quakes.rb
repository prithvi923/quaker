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
    payload = Place.find_results(count, days, wantsRegion)

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
end