#!/usr/bin/ruby
require 'rubygems'
require 'bundler/setup'
# require your gems as usual
require 'httparty'
require 'json'
require 'pirata'

# album of the day latest post
redditApiURL = "http://www.reddit.com/r/Albumoftheday/new.json?limit=1"
# itunes api album info
itunesApiURL = "https://itunes.apple.com/search?term=TERM&attribute=albumTerm&entity=album"
# get reddit title
response = HTTParty.get(redditApiURL)
json = JSON.parse(response.body)
latestRedditPostTitle = json['data']['children'][0]['data']['title']
# latestRedditPostTitle = "Waxahatchee - Cerulean Salt (2013) [WHAT]" # testing
# Get artist name from reddit title
artistName = latestRedditPostTitle.partition('-').first
artistName = artistName.gsub(/\s+/, "")
artistName = artistName.downcase
# Get album title from reddit title
albumTitle = latestRedditPostTitle.partition('-').last
albumTitle = albumTitle.partition('(').first
albumTitleWithSpaces = albumTitle.strip
albumTitle = albumTitle.gsub(/\s+/, "")
albumTitle = albumTitle.downcase
# Create itunes api url
itunesAlbumTitle = albumTitleWithSpaces.gsub(' ','+')
itunesApiURL['TERM'] = itunesAlbumTitle
# get itunes json
response = HTTParty.get(itunesApiURL)
json = JSON.parse(response.body)
# verify album via artist name and album name
check = false
json['results'].each do |item|
	if artistName == item['artistName'].downcase.gsub(/\s+/, "") && albumTitle == item['collectionName'].downcase.gsub(/\s+/, "")
		$result = item
		check = true
		break
	end
end
# if artist name did not match, abort.
if check == false
	abort("Failed: itunes could not find the album")
end
# print iTunes info
puts "Album Title: " + $result['collectionName']
puts "Artist Name: " + $result['artistName']
puts "Year Released: " + $result['releaseDate']
puts "Main Genre: " + $result['primaryGenreName']
puts ""
# search piratebay
searchTerm = $result['artistName'] + " " +$result['collectionName']
torrents = Pirata::Search.new(searchTerm, Pirata::Sort::SEEDERS).results
if torrents.empty?
	abort("Failed: No TPB results")
end
# get at most 10 search results
searchLength = torrents.length
if torrents.length > 10
	searchLength = 10
end
# list torrents
torrents.each_with_index do |torrent, index|
	break if index == searchLength;
	puts index.to_s + ": " + torrent.title
end
puts ""
# User input, pick a torrent to download
choiceNumber = 0
loop do
	print "Enter number of torrent to download or -1 to exit: "
	choiceNumber = gets.chomp
	choiceNumber = choiceNumber.strip
	# -1 exits
	if choiceNumber == "-1"
		abort("Exiting...")
	end
	# number must be in range
	if choiceNumber.to_i < -1 || choiceNumber.to_i > searchLength
		puts "Try again, not a valid choice."
	# input not a number
	elsif not choiceNumber.to_i.is_a? Integer
		puts "Try again, not a valid number."
	else
		break
	end
end

# Get info from config.json
file = File.read('config.json')
config = JSON.parse(file)
delugeApiURL = config['url'].chomp('/') + "/json"
delugeApiPassword = config['password']

# Get session cookie
delugeResponse = HTTParty.post(delugeApiURL, :body => {"id" => 1, "method" => "auth.login", "params" => [delugeApiPassword]}.to_json,:headers => {'Content-Type' => 'application/json'} )
jsonDelugeResponse = JSON.parse(delugeResponse)
# If the result of getting the session cookie failed, abort.
if jsonDelugeResponse['result'] != true
	abort("Failed: Deluge connection failed check url and password.")
end
# Start download
delugeDownload = HTTParty.post(delugeApiURL, :body => {"id" => 1, "method" => "webapi.add_torrent", "params" => [torrents[choiceNumber.to_i].magnet]}.to_json,:headers => {'Content-Type' => 'application/json', 'Cookie' => delugeResponse.headers['set-cookie']} )
puts "\nDownload started!"
