#!/usr/bin/ruby
require 'rss'
require 'nokogiri'
require 'fileutils'

def get_user_data
  puts 'Enter Email: '
  @email = gets.chomp
  puts 'Enter Password: '
  @pass = gets.chomp
  puts 'Press (y) to download all series else press any other key'
  @all_series = gets.chomp
end

def fetch_rss_file
  url = URI.open('https://gorails.com/episodes/pro.rss', http_basic_authentication: [@email, @pass]).read
  @rss = RSS::Parser.parse(url, false)
end

def fetch_series_title
  doc = Nokogiri::HTML(URI.parse(@series_url).open)
  [doc.css('h1').text, doc.css('div[id^="episode_"]')]
end

def add_url_to_episodes(episodes)
  episodes.map do |ep|
    data = { id: ep['id'].delete('episode_'), title: ep.css('h4').first.text.strip }
    @rss.items.each do |item|
      next unless data[:title] == item.title.strip

      data[:url] = item.enclosure.url
      data[:size] = item.enclosure.length / (1024 * 1024)
      break
    end
    data
  end
end

def download_individual_series
  series_title, episodes = fetch_series_title
  episodes_with_urls = add_url_to_episodes(episodes)
  folder_name = "series/#{series_title}"
  existing_files = Dir.glob("#{folder_name}/*.mp4").map { |f| f.split('/').last.split('.').first }
  FileUtils.mkdir_p folder_name

  episodes_with_urls.each_with_index do |ep, index|
    title = "#{ep[:id]}-#{ep[:title].downcase.tr('^A-Za-z0-9', '_')}"
    if existing_files.include? title
      puts "\n'#{ep[:title]}' Already Downloaded as '#{title}'\n\n"
      next
    end
    filename = File.join(folder_name, title)
    puts "Downloading '#{ep[:title]}'--#{ep[:size]}mb (#{index + 1}/#{episodes_with_urls.size})"
    `curl --progress-bar #{ep[:url]} -o "#{filename}.tmp"; mv "#{filename}.tmp" "#{filename}.mp4"`
  end
end

def fetch_all_series_title
  url = 'https://gorails.com/series'
  doc = Nokogiri::HTML(URI.parse(url).open)
  series_list = doc.css(
    'a[class="flex h-full border border-gray-100 rounded-md shadow bg-white"]',
    'a[class="hover:underline"]'
  ).map { |node| node['href'] }

  series_list.each do |series|
    @series_url = "https://gorails.com#{series}"
    download_individual_series
  end
end

get_user_data
fetch_rss_file

if @all_series&.downcase == 'y'
  fetch_all_series_title
else
  puts 'Enter Series URL. Eg: https://gorails.com/series/testing-ruby-on-rails: '
  @series_url = gets.chomp
  download_individual_series
end
