require 'net/http'
require 'uri'
require 'xmlsimple'
require 'json'
require 'pry'

def get_rss(url)
    # Fetches an RSS feed from the URL
    # Returns it as a Ruby object
    uri = URI.parse(url)
    rss = Net::HTTP.get_response(uri).body
    # Convert XML to a Ruby hash
    XmlSimple.xml_in(rss)
end

def parse_headlines(url, title_field, link_field)
    # Parses headlines with links from the URL of an RSS feed
    # When passing the link_field, you may pass a field that begins with an HTML link to the headline or a field with only the URL
    # Returns a an array of hashes each with a headline and url key
    data = get_rss(url)

    new_items = []

    # Iterate through the XML returned from the feed
    data['channel'][0]['item'].each_with_index do |item, index|
        item.each do |k, v|
            # Pull out the title and link fields
            if [title_field, link_field].include? k
                # Create a new hash inside the array unless it exists
                new_items.insert(index, {}) unless new_items[index]
                # Add the title or URL to the hash at the current index
                new_items[index].merge!(:title => v[0]) if k == title_field
                if k == link_field && v[0].match(/^<a\shref=/)
                    new_items[index].merge!(:url => v[0].match(/"(http:\/\/.*)"/)[1])
                elsif k == link_field
                    new_items[index].merge!(:url => v[0]) if k == link_field
                end

            end
        end
    end
    new_items
end

def load_headlines_json(file)
    # Loads a JSON file
    # Returns a Ruby object of the file's contents
    JSON.parse(IO.read(file))['headlines']
end

def add_onion_value!(object, onion)
    # Pass the object and a boolean for 'onion'
    # Modifies the object in place adding the boolean passed as the 'onion' hash key
    object.each do |headline|
        headline.merge!(:onion => onion)
    end
end

def save_headlines_json!(object, file)
    # Dumps a JSON string of an object and writes it to a file

    # Add 'headlines' to the top level of the hash
    object = {:headlines => object}
    IO.write(file, JSON.dump(object))
end

def merge_headlines(*headlines_objects)
    # Merges multiple headlines objects insuring values are unique
    headlines_objects.inject(:+).inject([]) {|result,h| result << h unless result.include?(h); result }
end

# App interface
all = []
while true do
    print "Feed URL (leave blank if done): "
    $stdout.flush
    url = gets.chomp

    if url == ""
        break
    else
        print "Headline title field: "
        $stdout.flush
        title_field = gets.chomp
        print "Link field: "
        $stdout.flush
        link_field = gets.chomp
        puts "Fetching headlines..."
        feed = parse_headlines(url, title_field, link_field)
        print "Onion stories? ('true' or 'false'): "
        $stdout.flush
        onion = gets.chomp
        add_onion_value!(feed, onion)
        all << feed
    end
end

print "Path of JSON file to merge (blank for none): "
$stdout.flush
other_file = gets.chomp
other_file = load_headlines_json(other_file) unless other_file == ""
all << other_file unless other_file == ""
print "Path and filename for output: "
$stdout.flush
output = gets.chomp
save_headlines_json!(merge_headlines(*all), output)
puts "File #{output} saved."