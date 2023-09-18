# GoRails Downloader

This script downloads all the videos from a GoRails series.

## Requirements

* Ruby
* Nokogiri
* RSS

## Installation

1. Install Ruby
2. Install Nokogiri: `gem install nokogiri`
3. Install RSS: `gem install rss`

## Usage

1. Clone this repository
2. Run `ruby download-series.rb`
3. Enter your GoRails email and password
4. Enter the URL of the series you want to download
5. The script will download all the videos from the series to a folder named `series/<series_title>`

## Code Explanation

The script consists of the following steps:

1. Get user data (email, password, and series URL)
2. Fetch the RSS feed for the gorails pro.
3. Fetch the series title and episodes
4. Add the URL to each episode from the RSS feed.
5. Download the files.

Made with :heart: and ![Ruby](https://img.shields.io/badge/-Ruby-000000?style=flat&logo=ruby)

#### DISCLAIMER: This software is for educational purposes only. This software should not be used for illegal activity. The author is not responsible for its use.
