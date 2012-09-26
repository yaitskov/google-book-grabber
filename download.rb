#!/usr/bin/jruby
# encoding: utf-8
require 'uri'
require 'cgi'
require 'httpclient'
require 'optparse'
require 'json'
require 'fileutils'
require 'prawn'

# Daneel Yaitskov, 2012 
# my Google Book Downloader
# rtfm.rtfm.rtfm@gmail.com

# There is one input parameter: one link to chunk of pages 
# example is http://books.google.ru/books?id=MFjNhTjeQKkC&lpg=PP1&dq=isbn%3A0981531644&pg=PR13&jscmd=click3
# It can be got from Firebug on browsing the book you to get

$bootUrl = nil
$quality = 1000
$skipDownloading = false
$bookName = 'bookx'
OptionParser.new do |o|
  o.on('-u BOOK_URL') { |url| $bootUrl = url }
  o.on('-n BOOK_NAME') { |name| $bookName = name }
  o.on('-q QUALITY') { |q| $quality = q.to_i }
  o.on('-s') { |skip| $skipDownloading = true }
  o.on('-h') { puts o; exit 1 }
  o.parse!
end

if !Dir.exist?($bookName) and File.exist?($bookName)
  puts "file #{$bookName} is exist"
  exit 1
end
if File.exist?($bookName + '.pdf')
  puts "file #{$bookName}.pdf is already exist"
  exit 1
end
if $quality < 500
  puts "-q quality #{$quality} is to low"
  exit 1
end
if $quality > 1500
  puts "-q quality #{$quality} is to high"
  exit 1
end
if $bootUrl == nil
  puts "-u parameter is missing"
  exit 1
end

class GoogleDownloader
  def buildHeader
    return { #request header
      'Host' => 'books.google.ru',
      'User-Agent' => 'Mozilla/5.0 (X11; Linux i686; rv:11.0) Gecko/20100101 Firefox/11.0',
      'Accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
      'Accept-Language' => 'en-us,en;q=0.5',
    }
  end
  def initialize(bootUrl, quality, bookName)
    @quality = quality
    @skippedPages = []
    @header = self.buildHeader
    @bookName = bookName
    parsedBootUrl = URI.parse(bootUrl)
    @path = parsedBootUrl.scheme + '://' + parsedBootUrl.host + '/' + parsedBootUrl.path
    @params = CGI.parse(parsedBootUrl.query)
    @params.each do |k,v| 
      @params[k] = v[0]
    end
    puts "params #{@params}"

    # page name => url with all keys where it is
    @pageMap = {}

    @client = HTTPClient.new
    #client.cookie_manager = nil
    # first call to get list all pages in the book
    content = self.getContent(bootUrl)
    puts "content length #{content.length}"
    #puts content
    content = JSON.parse(content)
    @pages = content['page'].find_all { |page| !page.has_key?('src') }
    @pages = @pages.map { |page| page['pid'] }
    puts "total pages #{@pages.length}"
    knownPages = content['page'].find_all { |page| page.has_key?('src') }
    knownPages.each do |page|
      @pageMap[page['pid']] = page['src']
    end

    # box for pages
    if !Dir.exist?(@bookName)
      Dir.mkdir @bookName
    end
  end
  def lookupPage(page)
    puts "looking for page #{page}..."
    @params['pg'] = page
    content = self.getContent(@path, @params)
    # puts "content #{content}"
    content = JSON.parse(content)
    knownPages = content['page'].find_all { |page| page.has_key?('src') }
    knownPages.each do |page|
      @pageMap[page['pid']] = page['src'] + '&w=' + $quality.to_s
      #puts "page #{page['pid']} = #{page['src']}"
    end        
  end
  # download page PNG images to @bookName folder
  def downloadPages
    puts "downloading page images..."
    pagei = 1
    @pages.each do |page|
      fileName = @bookName + '/' + page + '.png'
      puts "path #{fileName}"
      pagei += 1
      if File.exist?(fileName)
        puts "page #{page} is already exist"
        next
      end
      if !@pageMap.has_key?(page)
        self.lookupPage page
      end
      self.downloadOnePage page, fileName
    end    
  end
  def downloadOnePage(page, fileName)
    puts "downloading page #{page} => #{@pageMap[page]}"
    if @pageMap.has_key?(page)
      pageImage = self.getContent(@pageMap[page])
      pageFile = File.open(fileName, 'w')
      pageFile.write(pageImage)
      pageFile.close
    else
      puts "skipping #{page} cause its url is empty"
      @skippedPages << page
    end
  end
  def moveSkippedPages    
    @pages = @skippedPages
    puts "retry get pages #{@pages}"
    @skippedPages = []
  end
  def isSkippedPagesEmpty?
    return @skippedPages.empty?
  end
  def getContent(url, params = '')
    # puts "trying #{url} #{params}"    
    begin      
      return @client.get_content(url, params, @header)
    rescue HTTPClient::BadResponseError, HTTPClient::ReceiveTimeoutError => err 
      puts "retrying #{url} cause: #{err.message}"
      retry
    end
  end
  # compose PDF book from downloaded page images
  def renderBook
    puts "generating pdf document from downloaded images"
    doc = Prawn::Document.new(:page_size => 'A4')
    @pages.each do |page| 
      fileName = "#{@bookName}/#{page}.png"
      if !File.exist?(fileName)
        puts "page #{page} is not exist"
        next
      end  
      doc.image fileName, :position => :center, :vposition => :center, :fit => [ 800, 900 ]
      #doc.start_new_page  
    end

    puts "rendering"
    doc.render_file "#{@bookName}.pdf"    
  end
end

downloader = GoogleDownloader.new $bootUrl, $quality, $bookName
if !$skipDownloading
  while true 
    downloader.downloadPages
    if downloader.isSkippedPagesEmpty?
      break
    end
    downloader.moveSkippedPages
  end
end

downloader.renderBook
puts "#{$bookName}.pdf file is complete"


