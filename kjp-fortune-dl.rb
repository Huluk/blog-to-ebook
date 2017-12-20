#!/usr/bin/env ruby

require 'rubygems'
require 'mechanize'

agent = Mechanize.new

page = agent.get('http://kingjamesprogramming.tumblr.com')
# page = agent.get('http://kjprejects.tumblr.com/')

blockquote = /<\s*blockquote\s*>(.*?)<\s*\/\s*blockquote\s*>/xm
next_page = /Older/

quotes = page.body.scan(blockquote)
while page.link_with(:text => next_page)
  page = agent.click(page.link_with(:text => next_page))
  quotes += page.body.scan(blockquote)
end

out = []
quotes.flatten.each do |quote|
  out << Nokogiri::HTML(quote.gsub(/<.*?>/,' ').gsub(/\s+/,' ').strip).text
  out << '%'
end

# TODO automatically bring to max 80 chars per line
out[0...-1].each { |line| puts line }
