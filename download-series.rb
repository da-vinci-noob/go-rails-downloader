#!/usr/bin/ruby
require 'rss'
require 'nokogiri'
require 'fileutils'

def get_user_data
  puts 'Enter Email: '
  @email = gets.chomp
  puts 'Enter Password: '
  @pass = gets.chomp
  puts 'Enter Series URL. Eg: https://gorails.com/series/testing-ruby-on-rails: '
  @series_url = gets.chomp
end

def fetch_rss_file
  url = URI.open('https://gorails.com/episodes/pro.rss', http_basic_authentication: [@email, @pass]).read
  RSS::Parser.parse(url, false)
end

def fetch_series_title
  doc = Nokogiri::HTML(URI.open(@series_url))
  [doc.css('h1').text, doc.css('div[id^="episode_"]')]
end

def add_url_to_episodes(rss, episodes)
  episodes.map do |ep|
    data = { id: ep['id'].delete('episode_'), title: ep.css('h4').first.text.strip }
    rss.items.each do |item|
      next unless data[:title] == item.title.strip

      data[:url] = item.enclosure.url
      data[:size] = item.enclosure.length / (1024 * 1024)
      break
    end
    data
  end
end

def download_files
  rss = fetch_rss_file
  series_title, episodes = fetch_series_title
  episodes_with_urls = add_url_to_episodes(rss, episodes)

  folder_name = "series/#{series_title}"
  FileUtils.mkdir_p folder_name
  episodes_with_urls.each_with_index do |ep, index|
    title = "#{ep[:id]}-#{ep[:title].downcase.tr('^A-Za-z0-9', '_')}"
    filename = File.join(folder_name, title)
    puts "Downloading '#{ep[:title]}'--#{ep[:size]}mb (#{index + 1}/#{episodes_with_urls.size})"
    `curl --progress-bar #{ep[:url]} -o "#{filename}.tmp"; mv "#{filename}.tmp" "#{filename}.mp4"`
  end
end

get_user_data
download_files
