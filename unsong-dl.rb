#!/usr/bin/env ruby

require 'rubygems'
require 'mechanize'

SLEEP_TIME = 0.1 # good crawlers shouldn't ddos
TOC = 'http://unsongbook.com'
OUTFILE = 'unsong.html'

browser = Mechanize.new
toc = browser.get TOC

chapter_urls = toc.links.
  map{|l| l.uri.to_s }.
  keep_if{|u| u =~ /unsongbook.com\/chapter-/ or
              u =~ /unsongbook\.com\/interlude-/ or 
              u =~ /unsongbook\.com\/book-/ or
              u =~ /unsongbook\.com\/prologue/ or
              u =~ /unsongbook\.com\/epilogue/ }

book_text = '' # TODO add html header

chapter_urls.each do |url|
  html = browser.get(url)
  title = html.at('.pjgm-posttitle').to_html
  content = html.at('.pjgm-postcontent').inner_html.
    gsub(/<div class="sharedaddy.*\Z/m, '') # TODO make pretty

  # TODO Download images and store in media folder. Then replace URLs
  
  book_text << title
  book_text << content

  sleep SLEEP_TIME
end

File.open(OUTFILE, 'w') do |fi|
  fi.write book_text
end

# TODO pipe dat shit to pandoc. Make pandoc embed a css for proper page breaks at new chapters etc
