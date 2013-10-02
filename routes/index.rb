class MyQuaker < Sinatra::Application
  get '/' do
    erb :index
  end
end