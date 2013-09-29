class Place
  include DataMapper::Resource

  property :mag,     Float
  property :place,   String
  property :time,    Time, :key => true
  property :lat,     Float, :key => true
  property :lon,     Float, :key => true
end
