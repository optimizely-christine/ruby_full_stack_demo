require 'sinatra'
require 'httparty'
require 'optimizely'
require 'csv_hasher'

url = 'https://cdn.optimizely.com/json/7681190327.json'
datafile = HTTParty.get(url).body
optimizely = Optimizely::Project.new(datafile)


set :port, 8080
set :static, true
set :public_folder, "public"
set :views, "views"

class Item <
  Struct.new(:name, :color, :category, :price, :imageUrl)
end

def build_items()
  items = Array.new
  f = File.open("bin/items.csv", "r")
  f.each_line { |line|

    fields = line.split(',')

    item = Item.new

    item.name = fields[0]
    item.color = fields[1]
    item.category = fields[2]
    item.price = fields[3]
    item.imageUrl = fields[4]
    items.push(item)
  }
  return items
end

get '/' do
  items = build_items()

  erb :index, :locals => {'user_id' => '', 'filter_by' => '', 'feature_display' => 'none', 'data' => items}

end

post '/shop' do
  user_id = params[:user_id]
  filter_by = params[:filter]
  feature_display = 'none'
  items = build_items()

  variation_key = optimizely.activate('feature_rollout', user_id)
  if variation_key == 'holdback'
    items = items.sort_by { |k| k['category'].to_i }
  elsif variation_key == 'new_feature'
    # execute code for new_feature
    feature_display = 'block'
    items = items.sort_by { |k| k[filter_by].to_i }
  else
    # execute default code
    items = items.sort_by { |k| k['category'].to_i }
  end

  erb :index, :locals => {'user_id' => user_id, 'filter_by' => filter_by, 'feature_display' => feature_display, 'data' => items}
end

post '/buy' do
  user_id = params[:user_id]
  optimizely.track('purchased_item', user_id)
  erb :buy, :locals => {}
end
