#!/usr/bin/ruby
require 'rss'
require 'nokogiri'
require 'down'
require 'down/net_http'
require 'colorize'

def download_all_series?
  puts 'Press (y) to download all series else press any other key'
  @all_series = gets.chomp
end

def fetch_rss_file
  url = URI.open('https://gorails.com/episodes/pro.rss', http_basic_authentication: [email, pass]).read
  @rss = RSS::Parser.parse(url, false)
end

def fetch_series_title
  doc = Nokogiri::HTML(URI.parse(@series_url).open)
  [doc.css('h1').text.strip, doc.css('div[id^="episode_"]')]
end

def add_url_to_episodes(episodes)
  episodes.map do |ep|
    data = { id: ep['id'].delete('episode_'), title: ep.css('h4').first.text.strip }
    @rss.items.each do |item|
      next unless data[:title] == item.title.strip

      data[:url] = item.enclosure.url
      data[:pubDate] = item.pubDate
      data[:ext] = item.enclosure.type&.split('/')&.last || 'mp4'
      break
    end
    data
  end
end

def download_individual_series
  series_title, episodes = fetch_series_title
  episodes_with_urls = add_url_to_episodes(episodes)
  folder_name = "series/#{series_title}"
  existing_files = Dir.glob("#{folder_name}/*.mp4").map { |f| f.split('/').last }
  FileUtils.mkdir_p folder_name

  episodes_with_urls.each_with_index do |ep, index|
    title = "#{ep[:id]}-#{ep[:title].tr('^A-Za-z0-9 ', '_')}-#{ep[:pubDate].strftime('%d %b %Y')}.#{ep[:ext]}"
    if existing_files.include? title
      puts "'#{ep[:title].red}' Already Downloaded as '#{title.green}'\n\n"
    elsif ep[:url].empty?
      puts "No URL available for '#{title.blue}' in '#{folder_name.blue}\n\n".red
    else
      download_episode(ep[:url], title, index, episodes_with_urls.size, folder_name)
    end
  end
end

def download_episode(url, title, index, episode_count, folder_name)
  filename = File.join(folder_name, title)
  Down.download(
    url,
    destination: filename,
    content_length_proc: lambda { |content_length|
      @total = content_length
      puts "Downloading '#{title.green}' (#{(index + 1).to_s.magenta}/#{episode_count.to_s.magenta}) in #{folder_name.green}"
      puts "Total size: #{content_length / 1000 / 1000} MB"
    },
    progress_proc: lambda { |progress|
      if @total
        percent = (progress.to_f / @total * 100).round(2)
        print "\rDownloading: #{percent}% complete".red
      else
        print "\rDownloading: #{progress} bytes".red
      end
    }
  )

  puts "\nDownload complete: #{filename.green}\n\n"
end

def fetch_all_series_title
  url = 'https://gorails.com/series'
  doc = Nokogiri::HTML(URI.parse(url).open)
  series_list = doc.css('a.btn[href*="/series/"]').map { |node| node['href'] }

  series_list.each do |series|
    @series_url = "https://gorails.com#{series}"
    download_individual_series
  end
end

def load_env
  env_file = File.join(Dir.pwd, '.env')
  return unless File.exist?(env_file)

  File.open(env_file).each_line do |env|
    key, value = env.split('=')
    ENV[key.to_s] = value.strip
  end
end

def email
  @email ||=
    if ENV['GO_RAILS_USER'].to_s.empty?
      puts 'Enter Email: '
      gets.chomp
    else
      ENV['GO_RAILS_USER']
    end
end

def pass
  @pass ||=
    if ENV['GO_RAILS_PASS'].to_s.empty?
      puts 'Enter Password: '
      gets.chomp
    else
      ENV['GO_RAILS_PASS']
    end
end

load_env
download_all_series?
fetch_rss_file

if @all_series&.downcase == 'y'
  fetch_all_series_title
else
  puts 'Enter Series URL. Eg: https://gorails.com/series/testing-ruby-on-rails: '
  @series_url = gets.chomp
  download_individual_series
end
