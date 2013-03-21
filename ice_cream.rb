# user sends in the text address, get lat/long from geo api
# send lat/long into places api, rankby distance keyword ice cream
# scrape for lat/long and names of ice cream shops

#send that into directions api, and get directions

require 'rest-client'
require 'json'
require 'addressable/uri'
require 'nokogiri'

def everything

  user_lat_long = get_lat_long_of_current(get_address_from_user)
  shops = get_nearby_shops(user_lat_long)
  show_nearby(shops)
  chosen_shop = shops[shop_select]
  shop_lat_long = parse_lat_long_from_shop(chosen_shop)
  directions_hash = get_directions(user_lat_long, shop_lat_long)
  directions = parse_directions(directions_hash)
  show_directions(directions)
  #
  #http://maps.googleapis.com/maps/api/directions/json?origin=Toronto&destination=Montreal&sensor=false&mode=walking

end

def parse_directions(directions_hash)
  start_addy = directions_hash["routes"][0]["legs"][0]["start_address"]
  end_addy = directions_hash["routes"][0]["legs"][0]["end_address"]
  directions = []
  directions_hash["routes"][0]["legs"][0]["steps"].each do |step|
    # doc = Nokogiri::HTML(step["html_instructions"])
    # (doc.at_css "div").content = " #{(doc.at_css "div").content}"
    # text_instruction = doc.text
    directions <<  {
      :instructions => step["html_instructions"].gsub(/<\/?[^>]+>/,' '),
      :distance => step["distance"]["text"] }
  end
  [start_addy, directions, end_addy]
end

def show_directions(directions_array)
  start_addy, directions, end_addy = directions_array
  puts "\n\nStart address: #{start_addy}"
  directions.each_with_index do |step, i|
    puts "Step #{i+1}: #{step[:instructions]}"
    puts "      Distance: #{step[:distance]}"
  end
  puts "End address: #{end_addy}\n\n"
end

def get_directions(user_lat_long, shop_lat_long)
  from = user_lat_long.join(',')
  to = shop_lat_long.join(',')

  a = Addressable::URI.new(
     :scheme => "https",
     :host => "maps.googleapis.com",
     :path => "/maps/api/directions/json",
     :query_values => { :origin => from,
                        :destination => to,
                        :sensor => "false",
                        :mode => "walking" }
  )
  response = RestClient.get(a.to_s)
  JSON.parse(response)
end



def get_address_from_user
  puts "input your address (ex: street, city, state)"
  address = gets.chomp
end


def parse_lat_long_from_shop(shop)
  lat = shop["geometry"]["location"]["lat"]
  long = shop["geometry"]["location"]["lng"]
  [lat, long]
end
##  http://maps.googleapis.com/maps/api/geocode/json?address=1600+Amphitheatre+Parkway,+Mountain+View,+CA&sensor=true_or_false

###  160 Folsom, San Francisco, CA

def get_lat_long_of_current(address)

  a = Addressable::URI.new(
     :scheme => "https",
     :host => "maps.googleapis.com",
     :path => "/maps/api/geocode/json",
     :query_values => { :address => address,
                        :sensor => "false"}
  )
  response = RestClient.get(a.to_s)

  response_json = JSON.parse(response)
  lat = response_json["results"][0]["geometry"]["location"]["lat"]
  long = response_json["results"][0]["geometry"]["location"]["lng"]
  [lat, long]
end


# https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=-33.8670522,151.1957362&radius=500&types=food&name=harbour&sensor=false&key=AddYourOwnKeyHere

def get_nearby_shops(lat_long)
  lat, long = lat_long
  a = Addressable::URI.new(
     :scheme => "https",
     :host => "maps.googleapis.com",
     :path => "/maps/api/place/nearbysearch/json",
     :query_values => { :key => "AIzaSyAMMYCfB0-Krv9vQWEUOcj2oWwOFTXX80s",                             :location => "#{lat},#{long}" ,
                       :rankby => "distance" ,
                      :keyword => "ice cream",
                      :sensor => "false" }
  )
  response = RestClient.get(a.to_s)
  shops = JSON.parse(response)["results"]
  shops
end

def show_nearby(shops)
  shops.each_with_index do |shop, i|
    puts "#{i+1} || #{shop["name"]}"
  end
end

def shop_select
  puts "select the number of your ice cream shop"
  shop_number = gets.chomp.to_i - 1
end

everything


