#!/usr/bin/env ruby

APP_NAME = './down_ebook' # TODO rename

# TODO require bundler?
# TODO make dir for images, what then?
require 'open-uri'
require 'yaml'
require 'optparse'
require 'mechanize'
require 'addressable'
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

# TODO load config: first piped, then arg -c, then local, then default
options = {
  sleep_time: 0.1,
  output_directory: '.',
  conversion_command: "pandoc -s -c css.css -o %s.epub %s",
}
config = YAML.load(File.read('config.yml'))
options = Hashie::Mash.new(options.merge config)
 
optparse = OptionParser.new do|opts|
  opts.banner = "Usage: #{APP_NAME} [-c config] -o output_directory"

  opts.on('-c', '--config CONFIG', 'path to configuration file') do |config|
    # TODO error handling
    options.config = YAML.load(File.read(config))
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

# TODO ensure output path exists

def toc_url_to_chapter_links(toc_url, path, regex)
  browser = Mechanize.new
  toc = browser.get(toc_url).at(path)
  links = toc.search('a').map{ |link| link['href'] }
  return links.keep_if{ |u| u =~ regex }.uniq
end

def read_url(url)
  begin
    return open(url).read
  rescue URI::InvalidURIError
    return open(Addressable::URI.encode_component(url)).read
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
    url = img['src']
    extension = File.extname(url).gsub(/\?.*$/,'')
    outfile = File.join(outdir, "#{url.hash}#{extension}")
    img['src'] = outfile
    File.open(outfile, 'w') do |file|
      # TODO error handling
      file.write(read_url(url))
    end
  end
  return document
end

regex = /#{options.toc_regex}/i
links = toc_url_to_chapter_links(options.toc_url, options.content_path, regex)[0..3]

titles = []
contents = []
links.each do |url|
  document = Nokogiri::HTML.parse(read_url(url))
  titles << document.at(options.title_path)
  contents << document.at(options.content_path)
  sleep options.sleep_time
end

image_dir = File.join(options.output_directory, 'images')
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

system(options.conversion_command % [options.filename, html_file])
