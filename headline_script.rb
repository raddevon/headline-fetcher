require 'net/http'
require 'uri'
require 'rexml/document'

onion_uri = URI.parse('http://feeds.theonion.com/theonion/daily')

# Shortcut
response = Net::HTTP.get_response(onion_uri)

# Will print response.body
Net::HTTP.get_print(uri)

# Full
http = Net::HTTP.new(uri.host, uri.port)
response = http.request(Net::HTTP::Get.new(uri.request_uri))