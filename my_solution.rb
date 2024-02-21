require "http"
require "json"
require "ascii_charts"

g_maps_key = ENV.fetch("GMAPS_KEY")

p_weather_key = ENV.fetch("PIRATE_WEATHER_KEY")

puts "Let's find out if you need an umbrella! \n\nWhere are you?"
location = gets.chomp.capitalize

# Once we have the user's location, we grab the latitude and longitude from Google Maps with the code below.
location_url = "https://maps.googleapis.com/maps/api/geocode/json?address=#{location}&key=#{g_maps_key}"

map_res = HTTP.get(location_url)

parsed_response = JSON.parse(map_res)

res_hash = parsed_response.fetch("results")[0]

# In the rare event that the location can't be found, we exit with a human-readable error.
if res_hash == nil
  abort("Location not found.")
end

geo_hash = res_hash.fetch("geometry")

location_hash = geo_hash.fetch("location")

lat = location_hash.fetch("lat")
lng = location_hash.fetch("lng")

# Now that we have the latitude and longitude, we can find their weather forecast.

weather_url = "https://api.pirateweather.net/forecast/#{p_weather_key}/#{lat},#{lng}"

weather_res = HTTP.get(weather_url)

parsed_weather_res = JSON.parse(weather_res)

currently_hash = parsed_weather_res.fetch("currently")

temp = currently_hash.fetch("temperature").round

weather = currently_hash.fetch("summary").downcase

need_umbrella = false

case weather
when "rain", "snow", "sleet" 
  need_umbrella = true
  if "rain"
    weather = "raining"
  elsif "snow"
    weather = "snowing"
  elsif "sleet"
    weather = "sleeting"
  end
end

# Next, we're going to go through the hourly forecasts to check the precipitation percentages.
hourly_hash = parsed_weather_res.fetch("hourly")

hourly_data = hourly_hash.fetch("data")

i = 0

hourly_need_umbrella = false

# Let's look around for weather events in the next hour

minute_hash = parsed_weather_res.fetch("minutely")

minute_array = minute_hash.fetch("data")

minute_weather_type = ""

minute_weather_time = 0

x = 0

minute_array.each_with_index do |item, index|
 precip_type = item.fetch("precipType")

 if precip_type != "none"
  minute_weather_type = precip_type
 end
end

if minute_weather_type != ""
  minute_weather_time = (minute_array.find_index {|e| e["precipType"] != "none"}) + 1
end


# Next, I'm initiatializing an array to store the index and value from the for loop for display in the ascii chart.
precip_data_arr = []

while i <= 12
  precip_hash = hourly_data[i]
  probability = precip_hash.fetch("precipProbability")

  if probability > 0.1
    hourly_need_umbrella = true
  end

  percent_display = probability * 100

  precip_data_arr[i] = [i, percent_display.round()]

  i += 1
end

puts "\nYour coordinates are #{lat.round(7)}, #{lng.round(7)}."

puts "It's currently #{temp}°F in #{location}. It's #{weather}, so you #{need_umbrella ? "do" : "don't"} need an umbrella right now."

if minute_weather_time > 5 && minute_weather_time < 60 && minute_weather_type != weather
  puts "Next hour: Possible #{minute_weather_type} starting in #{minute_weather_time} minutes."
elsif minute_weather_type == ""
  puts "Next hour: Weather looks #{weather}."
end

puts "\nHours from now vs Precipitation probability"

puts AsciiCharts::Cartesian.new(precip_data_arr[1..12], :bar => true, :hide_zero => true).draw

puts "In the next 12 hours, #{hourly_need_umbrella ? "you might need an umbrella." : "you won't need an umbrella."}"
