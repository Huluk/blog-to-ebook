#!/usr/bin/env ruby

# TODO require bundler?
# TODO include cover image, pass to pandoc
require 'open-uri'
require 'io/wait'
require 'yaml'
require 'optparse'

require 'rubygems'
require 'open_uri_redirections'
require 'mechanize'
require 'addressable/uri'
require 'hashie'

HTML_HEADER = <<EOF
!DOCTYPE HTML>
<html>
  <head>
    <title>%s</title>
    <author>%s</author>
  </head>
<body>
EOF
HTML_FOOTER = "</body>\n</html>"

options = Hashie::Mash.new({
  'sleep_time' => 0.1,
  'output_directory' => '.',
  'css_file' => "http://github.com/Huluk/blog-to-ebook/css.css",
  'conversion_command' => "pandoc -s -c %3$s -o %2$s.epub %1$s",
})
local_config = File.join(File.dirname(__FILE__), 'config.yml')
if File.exist? local_config
  options.merge! YAML.load(File.read(local_config))
end
 
optparse = OptionParser.new do|opts|
  opts.banner = "Usage: #{$0} [-c config] -o output_directory"

  opts.on('-c', '--config CONFIG', 'path to configuration file') do |config|
    options.config = config
  end

  opts.on('-o', '--output PATH', 'write path') do |path|
    options.output_directory = path
  end

  opts.on('-h', '--help', 'displays this message') do
    puts opts
    exit
  end
end

optparse.parse!

if options.config?
  begin
    options.merge! YAML.load(File.read(options.config))
  rescue LoadError
    $stderr.puts "no such file: #{options.config}"; exit
  rescue Psych::SyntaxError, TypeError => e
    $stderr.puts "cannot read config file: #{e.message}"; exit
  end
end

if $stdin.ready?
  begin
    options.merge! YAML.load($stdin.read)
  rescue Psych::SyntaxError, TypeError => e
    $stderr.puts "invalid config syntax in stdin: #{e.message}"; exit
  end
end

unless File.directory?(options.output_directory)
  Dir.mkdir(options.output_directory)
end

def toc_url_to_chapter_links(toc_url, path, regex)
  browser = Mechanize.new
  toc = browser.get(toc_url).at(path)
  links = toc.search('a').map{ |link| link['href'] }
  return links.keep_if{ |u| u =~ regex }.uniq
end

def read_url(url)
  begin
    return open(url, allow_redirections: :all).read
  rescue URI::InvalidURIError
    url = Addressable::URI.encode_component(url)
    return open(url, allow_redirections: :all).read
  end
end

def clean_document(document, garbage_path=nil, &block)
  document.search(garbage_path).remove if garbage_path
  if block
    return yield(document)
  else
    return document
  end
end

def download_images_and_update_urls(document, outdir)
  document.search('img').each do |img|
    url = img['src'].gsub(/\?.*$/,'')
    extension = File.extname(url)
    outfile = File.join(outdir, "#{url.hash}#{extension}")
    img['src'] = outfile
    File.open(outfile, 'w') do |file|
      begin
        file.write(read_url(url))
      rescue
        $stderr.puts "error while saving image: #{url}"
      end
    end
  end
  return document
end

regex = /#{options.toc_regex}/i
links = toc_url_to_chapter_links( options.toc_url, options.content_path, regex)

puts 'downloading:'
titles = []
contents = []
links.each do |url|
  puts url
  document = Nokogiri::HTML.parse(read_url(url))
  titles << document.at(options.title_path)
  contents << document.at(options.content_path)
  sleep options.sleep_time
end

image_dir = File.join(options.output_directory, 'images')
Dir.mkdir(image_dir) unless File.directory?(image_dir)
contents.map!{ |content|
  content = clean_document(content, options.garbage_path)
  download_images_and_update_urls(content, image_dir)
}
titles.map!{ |title| options.chapter_title_format % title.text }
contents.map! &:inner_html
book = (HTML_HEADER % [options.title, options.author]) +
  titles.zip(contents).map(&:join).join +
  HTML_FOOTER

html_file = File.join(options.output_directory, options.filename + '.html')
File.open(html_file, 'w') do |file|
  file.write book
end

system(options.conversion_command %
       [html_file, options.filename, options.css_file])
