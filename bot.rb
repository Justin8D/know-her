require 'twitter'
require 'tempfile'
require 'rmagick'
require 'dotenv'
require 'ostruct'
require 'open-uri'
require 'rubygems'
include Magick

Dotenv.load

@er_url = "http://api.wordnik.com/v4/words.json/search/.*er$?allowRegex=true&caseSensitive=true&minCorpusCount=5&maxCorpusCount=-1&minDictionaryCount=1&maxDictionaryCount=-1&minLength=3&maxLength=-1&skip=0&limit=5000&api_key=5868a3e53667cda37400208fb640f5c3bd1d214250a4700a9"
@or_url = "http://api.wordnik.com/v4/words.json/search/.*or$?allowRegex=true&caseSensitive=true&minCorpusCount=5&maxCorpusCount=-1&minDictionaryCount=1&maxDictionaryCount=-1&minLength=3&maxLength=-1&skip=0&limit=5000&api_key=5868a3e53667cda37400208fb640f5c3bd1d214250a4700a9"

def wordnik_parse (input)
  JSON.parse(input, symbolize_names: true,
                      object_class: OpenStruct)
                      .searchResults.map(&:word)
end

def random_word
  er_words = wordnik_parse(open(@er_url).read)
  or_words = wordnik_parse(open(@or_url).read)
  @words = er_words + or_words
end

def er_text
  "#{@word.capitalize}?! I don't even KNOW her!"
end

def search_url(query)
  "https://api.imgur.com/3/gallery/search/top/week/search?q=#{query}"
end

def curl_cmd(client_id, url)
  "curl -s -H \"Authorization: Client-ID #{client_id}\" \"#{url}\""
end

def random_imgur_url
  json = `#{curl_cmd(ENV['IMGUR_CLIENT_ID'], search_url(@word))}`
  response = JSON.parse(json, symbolize_names: true,
                              object_class: OpenStruct)
  sfw_urls = response.data.reject(&:nsfw)
                          .reject(&:animated)
                          .reject(&:is_album)
                          .map(&:link).sample
end

def image(url)
  puts url
  file = Tempfile.new('er image')
  file.write(`curl -s #{url}`)
  file.rewind
  bin = File.open(file,'r'){ |f| f.read }
  return nil unless bin.length > 0
  image = Image.from_blob(bin).first
  image.change_geometry!('500x') { |c,r,i| i.resize!(c,r) }

  resized_image = (ImageList.new << image).append(true)

  file.write(resized_image.to_blob)
  file.rewind
  file
end

client = Twitter::REST::Client.new do |config|
  config.consumer_key       = ENV['TWITTER_CONSUMER_KEY']
  config.consumer_secret    = ENV['TWITTER_CONSUMER_SECRET']
  config.access_token        = ENV['TWITTER_OAUTH_TOKEN']
  config.access_token_secret = ENV['TWITTER_OAUTH_SECRET']
end

@good_image = nil

random_word

while @good_image == nil do
  @word = @words.sample
  @good_image = image(random_imgur_url)
end

begin
   tries ||= 5
   client.update_with_media(er_text, @good_image)
 rescue Twitter::Error => e
  retry unless (tries -= 1).zero?
 end