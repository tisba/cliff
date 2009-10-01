#!/usr/bin/env ruby

# = USAGE
#  clif < file.txt
#  clif abcdef01234567890 > output.txt
#

require 'open-uri'
require 'net/http'
require 'rubygems'
require 'json'

class Clif
  FP_URL = "http://www.friendpaste.com/"   
    
  class <<self
    def create(content)
      snippet = Snippet.new(content)
      snippet.save
      copy(snippet.url)
      snippet
    end

    def get(doc_id)
      raw = open(FP_URL + doc_id, "Accept" => "application/json").read
      Snippet.new(JSON.parse(raw))
    end
    
    # Copy content to clipboard
		def copy(content)
			case RUBY_PLATFORM
			when /darwin/
				return content if `which pbcopy`.strip == ''
				IO.popen('pbcopy', 'r+') { |clip| clip.print content }
			when /linux/
				return content if `which xclip  2> /dev/null`.strip == ''
				IO.popen('xclip', 'r+') { |clip| clip.print content }
			when /i386-cygwin/
				return content if `which putclip`.strip == ''
				IO.popen('putclip', 'r+') { |clip| clip.print content }
			end

			content
		end
  end

  class Snippet
    attr_reader :snippet_id
    
    def initialize(data)
      data = {"snippet" => data} unless data.kind_of? Hash

      @data = { "title" => (data["title"] or ""),
                "snippet" => data["snippet"],
                "language" => (data["language"] or "text")
               }
    end
    
    def url
      FP_URL + @snippet_id     
    end

    def method_missing(meth, *args, &blk)
      super unless @data.keys.include?(meth.to_s)
      @data[meth.to_s] 
    end

    def save
      uri = URI.parse(Clif::FP_URL)
      headers = {"Content-Type"  => "application/json", "Accept" => "application/json"}
      res = Net::HTTP.new(uri.host, uri.port).post(uri.path, @data.to_json, headers)
      if res.kind_of? Net::HTTPSuccess
        @snippet_id = JSON.parse(res.body)["id"]
      else
        puts "Something went wrong #{res.code.inspect}"
      end
    end
  end
end

if $stdin.tty?
  puts Clif.get(ARGV.first).snippet
else
  puts Clif.create($stdin.read).snippet_id
end