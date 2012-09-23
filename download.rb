#!/usr/bin/ruby
require 'uri'
require 'cgi'
require 'httpclient'
require 'optparse'
require 'json'
require 'fileutils'

# Daneel Yaitskov, 2012 
# my Google Book Downloader
# rtfm.rtfm.rtfm@gmail.com

# There is one input parameter: one link to chunk of pages 
# example is http://books.google.ru/books?id=MFjNhTjeQKkC&lpg=PP1&dq=isbn%3A0981531644&pg=PR13&jscmd=click3
# It can be got from Firebug on browsing the book you to get

#request header
header = {
  'Host' => 'books.google.ru',
  'User-Agent' => 'Mozilla/5.0 (X11; Linux i686; rv:11.0) Gecko/20100101 Firefox/11.0',
  'Accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
  'Accept-Language' => 'en-us,en;q=0.5',
  #'Accept-Encoding' => 'gzip, deflate',
  #'Connection' => 'keep-alive'
}

# response
# {"page":[{"pid":"PR13","src":"http://books.google.ru/books?id=MFjNhTjeQKkC\u0026pg=PR13\u0026img=1\u0026zoom=3\u0026hl=en\u0026sig=ACfU3U1wT-2JDzF5Eha2fsUe-A_m9KNZ5A","flags":0,"order":13,"uf":"http://books.google.ru/books_feedback?id=MFjNhTjeQKkC\u0026spid=AFLRE7244Si5wmg-jUTYz6joMap5gx8ozhwfIshYAhUJW3EkwDLNNRI\u0026ftype=0"},{"pid":"PR12","src":"http://books.google.ru/books?id=MFjNhTjeQKkC\u0026pg=PR12\u0026img=1\u0026zoom=3\u0026hl=en\u0026sig=ACfU3U1eNqXCGjVeEZUzVSwLKxMfSusO3Q"},{"pid":"PR14","src":"http://books.google.ru/books?id=MFjNhTjeQKkC\u0026pg=PR14\u0026img=1\u0026zoom=3\u0026hl=en\u0026sig=ACfU3U34XA644yrE3PZL09M2nMbV_CcM6Q"},{"pid":"PR15","src":"http://books.google.ru/books?id=MFjNhTjeQKkC\u0026pg=PR15\u0026img=1\u0026zoom=3\u0026hl=en\u0026sig=ACfU3U3JdIi8qZptNAPLi17qsqUutrnf2g"},{"pid":"PR16","src":"http://books.google.ru/books?id=MFjNhTjeQKkC\u0026pg=PR16\u0026img=1\u0026zoom=3\u0026hl=en\u0026sig=ACfU3U3QyRD3UGxo5NTYN2x-JHW6fHf46Q"},{"pid":"PP1"},{"pid":"PR4"},{"pid":"PR9"},{"pid":"PR10"},{"pid":"PR11"},{"pid":"PR12"},{"pid":"PR13"},{"pid":"PR14"},{"pid":"PR15"},{"pid":"PR16"},{"pid":"PR17"},{"pid":"PR18"},{"pid":"PR19"},{"pid":"PR20"},{"pid":"PR21"},{"pid":"PR22"},{"pid":"PR23"},{"pid":"PR24"},{"pid":"PR25"},{"pid":"PR26"},{"pid":"PR27"},{"pid":"PR28"},{"pid":"PR29"},{"pid":"PR30"},{"pid":"PR31"},{"pid":"PR32"},{"pid":"PR33"},{"pid":"PR34"},{"pid":"PR35"},{"pid":"PR36"},{"pid":"PR37"},{"pid":"PR38"},{"pid":"PR39"},{"pid":"PR40"},{"pid":"PA1"},{"pid":"PA2"},{"pid":"PA3"},{"pid":"PA4"},{"pid":"PA5"},{"pid":"PA6"},{"pid":"PA7"},{"pid":"PA8"},{"pid":"PA9"},{"pid":"PA1

$bootUrl = nil
OptionParser.new do |o|
  o.on('-u BOOK_URL') { |url| $bootUrl = url }
  o.on('-h') { puts o; exit 1 }
  o.parse!
end

if $bootUrl == nil
  puts "-u parameter is missing"
  exit 1
end

parsedBootUrl = URI.parse($bootUrl)
path = parsedBootUrl.scheme + '://' + parsedBootUrl.host + '/' + parsedBootUrl.path
params = CGI.parse(parsedBootUrl.query)
params.each do |k,v| 
  params[k] = v[0]
end
puts "params #{params}"
#exit 

# box for pages
FileUtils.rm_rf 'pages'
Dir.mkdir 'pages'

pageMap = {}

client = HTTPClient.new
#file = File.open("boot", "r")
#content = file.readlines.join

# first call to get list all pages in the book
content = client.get_content($bootUrl, '', header)
puts "content length #{content.length}"
puts content
content = JSON.parse(content)
pages = content['page'].find_all { |page| !page.has_key?('src') }
pages = pages.map { |page| page['pid'] }
puts "total pages #{pages}"
knownPages = content['page'].find_all { |page| page.has_key?('src') }
knownPages.each do |page|
  pageMap[page['pid']] = page['src']
end

pagei = 1
pages.each do |page| 
  puts "page #{pagei} => #{page}"
  pagei += 1
  if !pageMap.has_key?(page)
    puts "looking for page #{page}..."
    params['pg'] = page
    #puts "params #{params}\nheader #{header}"
    content = client.get_content(path, params, header)
    #puts "content #{content}"
    content = JSON.parse(content)
    knownPages = content['page'].find_all { |page| page.has_key?('src') }
    knownPages.each do |page|
      pageMap[page['pid']] = page['src']
    end    
  end  
  puts "ready to download page #{page} => #{pageMap[page]}"  
  pageImage = client.get_content(pageMap[page], '', header)
  pageFile = File.open('pages/' + page + '.png', 'w')
  pageFile.write(pageImage)
  pageFile.close
  exit
end



