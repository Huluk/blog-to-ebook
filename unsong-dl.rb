#!/usr/bin/env ruby

require 'rubygems'
require 'mechanize' # gem install mechanize, requires nokogiri
# require 'text/hyphen' # gem install text-hypen

TOC = 'http://unsongbook.com'
title = 'unsong'
options = '[interlude|chapter|book|prolog|epilog|arc]'
OUTFILE = 'unsong.html'

SLEEP_TIME = 0.1 # good crawlers shouldn't ddos

browser = Mechanize.new
toc = browser.get TOC

chapter_urls = toc.links.
  map{|l| l.uri.to_s }.
  keep_if{ |u| u =~ /#{title}.*#{options}/i }

book_text = '' # TODO add html header

chapter_urls.each do |url|
  html = browser.get(url)
  title = html.at('.pjgm-posttitle').inner_html
  content = html.at('.pjgm-postcontent').inner_html.
    gsub(/<div class="sharedaddy.*\Z/m, '') # TODO make pretty

  # TODO Download images and store in media folder. Then replace URLs
  # TODO maybe hyphenize content, unless pandoc does this
  
  book_text << "<h1>#{title}</h1>"
  book_text << content

  sleep SLEEP_TIME
end

File.open(OUTFILE, 'w') do |file|
  file.write book_text
end

# TODO pipe dat shit to pandoc. Make pandoc embed a css for proper page breaks at new chapters etc
