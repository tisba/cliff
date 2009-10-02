#!/usr/bin/env ruby

require 'open-uri'
require 'net/http'
require 'rubygems'
require 'json'
require "trollop"

class Clif
  FP_URL = "http://www.friendpaste.com/"   
    
  class <<self
    def languages
      @languages ||= Helpers.load_languages_from_cache
    end
 
    def create(content, params)
      snippet = Snippet.new(content, params)
      snippet.save
      Helpers.copy(snippet.url)
      return snippet
    end

    def get(doc_id)
      headers = {"Accept" => "application/json"}
      raw = open("#{FP_URL}/#{doc_id}", headers).read
      Snippet.new(JSON.parse(raw))
    end
  end

  class Helpers
    class << self
      def is_language?(opt)
        Clif.languages.flatten.include?(opt)
      end

      def fetch_languages
        open("#{FP_URL}/_all_languages").read
      end
            
      def cache_file_name
        File.join(ENV['HOME'], ".friendpaste_languages")
      end

      def refresh_languages_cache
        languages = fetch_languages
        File.open(cache_file_name, 'w+') {|f| f.write(languages) }
        JSON.parse(languages)
      end

      def load_languages_from_cache
        if File.exists?(cache_file_name)
          JSON.parse(File.read(cache_file_name))
        else
          refresh_languages_cache
        end
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
  end

  # Class for representing a snippet
  class Snippet
    attr_reader :snippet_id
    
    def initialize(data, params = {})
      data = {"snippet" => data} unless data.kind_of? Hash

      @data = { "title"    => "",
                "language" => "text"
               }.merge(data).merge(params)
    end

    def self.create(data)
      snippet = new(data)
      snippet.save
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

p Clif.languages.class


# Define some command-line options
opts = Trollop.options do
  version "v0.1 (by) Sebastian Cohnen, 2009"
  banner <<-BANNER
  Clif is a CLI-Client for friendpaste.com. It's not yet finished but
  should work. Currently only getting existing and creating new snippets
  is supported. Updates, Diffs, Versioning, etc. will soon follow!

  http://github.com/tisba/clif

  Usage:
  $ clif < file.txt
  $ cat mycode.rb | clif rb # Clif will try to find a matching language for syntax hl
  $ clif someexistingfile.txt # Clif will upload the contents of the file if it exists
  $ clif SOME_SNIPPET_ID > output.txt

  Note:
  When creating a new snippet, the complete URL is copied to your
  clipboard for direct usage on IRC and co.

  Clif is heavily inspired by the CLI-Clients for gist :-)
  
  BANNER
  opt :list_languages, "List all available languages", :default => false
  opt :refresh, "Refresh available languages", :default => false 
end

# List all available languages
if opts[:list_languages]
  Clif.languages.each { |lang| puts lang.join(': ') }
  exit
end

# Refresh available languages
if opts[:refresh]
  Clif::Helpers.refresh_languages_cache
  exit
end

# Let's rock!

# Let's see if our first param could be an existing file...
if ARGV.first and File.exists?(ARGV.first)
  input = File.read(ARGV.first)
  puts Clif.create(input, {}).snippet_id
  exit
end

if $stdin.tty?
  puts Clif.get(ARGV.first).snippet
else
  opts = {"language" => ARGV.first} if Clif::Helpers.is_language?(ARGV.first)
  puts Clif.create($stdin.read, opts).snippet_id
end