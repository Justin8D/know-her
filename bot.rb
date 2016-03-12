require 'twitter'
require 'tempfile'
require 'rmagick'
require 'dotenv'
require 'ostruct'
require 'open-uri'
require 'rubygems'
include Magick

Dotenv.load

def random_er
  @er_word = File.readlines('./er_words.txt').sample.chomp
end

def er_text
  "#{@er_word.capitalize}?! I don't even KNOW her!"
end

def search_url(query)
  "https://api.imgur.com/3/gallery/search/top/week/search?q=#{query}"
end

def curl_cmd(client_id, url)
  "curl -s -H \"Authorization: Client-ID #{client_id}\" \"#{url}\""
end

def random_imgur_url
  json = `#{curl_cmd(ENV['IMGUR_CLIENT_ID'], search_url(@er_word))}`
  response = JSON.parse(json, symbolize_names: true,
                              object_class: OpenStruct)
  sfw_urls = response.data.reject(&:nsfw)
                          .reject(&:animated)
                          .map(&:link).first
end

def image(url)
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

while @good_image == nil do
  random_er
  @good_image = image(random_imgur_url)
end

begin
   tries ||= 5
   client.update_with_media(er_text, @good_image)
 rescue Twitter::Error => e
  retry unless (tries -= 1).zero?
 end