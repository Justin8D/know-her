require 'twitter'
require 'tempfile'
require 'rmagick'
require 'dotenv'
require 'ostruct'
require 'open-uri'
require 'rubygems'
require 'wordnik'
include Magick

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
  @words.sample
end