#!/usr/bin/env ruby
require 'rubygems'
require 'webrick/httpproxy'
require 'ruby-debug'
require 'zlib'
require 'stringio'

################################
@include = /http:\/\/.*//
@exclude = /google/
################################

def self.pass? request_line
  request_line =~ @include and !(request_line =~ @exclude)
end

def inflate(s)
  s_io=StringIO.new(s)
  Zlib::GzipReader.new(s_io).read
end


@proxy_port    = ARGV[0] || 8080
@search_body   = ARGV[1]
 
# Optional flags
@print_headers  = false
@print_body     = true
@pretty_colours = true

 
server = WEBrick::HTTPProxyServer.new(
    :Port => @proxy_port,
    :AccessLog => [] ,# suppress standard messages
 
    :ProxyContentHandler => Proc.new do |req,res|

    next unless pass? req.request_line.chomp and res.status_line =~ /200/


    #TODO URL encoding check for none ascii charactor
    
    path=req.path + (req.path =~/\/$/ ? 'index.html' :'') #路径是否为目录
    
    save_to=File.join(req.host,path)
    
    dir=File.dirname save_to

    
    puts "-"*75
    puts ">>> #{req.request_line.chomp} >>> #{save_to}\n"


    
    # req.header.keys.each do |k|
    #     puts "#{k.capitalize}: #{req.header[k]}" if @print_headers
    # end
 
    # puts "<<<" if @print_headers
    # puts res.status_line if @print_headers
    # res.header.keys.each do |k|
    #     puts "#{k.capitalize}: #{res.header[k]}" if @print_headers
    # end
    
    unless res.body.nil? then
      
    
    FileUtils.mkdir_p dir unless File.exists? dir  
    
    #TODO skip saved file
    
    #TODO deal with the absolute url
    
    #Deal Width Gzip
    file_content=res.body
    file_content= res.header["content-encoding"] =~ /gzip/ ? (inflate file_content) : file_content
        open(save_to,"wb"){|os|
          os.write(file_content)
        }
      end
    end ,
    
  :RequestCallback => Proc.new{|req,res| 
    #disable cache
    #TODO should check if file is downloaded
    if pass? req.request_line.chomp
      # req.header["cache-control"]=["no-cache"]
      # req.header.delete("if-modified-since")
      # req.header.delete("if-none-match")
    end
}
    
)
trap("INT") { server.shutdown }
server.start

