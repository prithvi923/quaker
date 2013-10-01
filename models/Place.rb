# Model of a Place
class Place
  # DataMapper Resource
  include DataMapper::Resource

  # Storing only what's needed for calculations:
  # :lat and :lon for calculating regions
  # :time for calculating time range
  # Combination of :time, :lat, :lon is the key for determining uniqueness of an earthquake
  property :mag,     Float
  property :place,   String
  property :time,    Time, :key => true
  property :lat,     Float, :key => true
  property :lon,     Float, :key => true
end