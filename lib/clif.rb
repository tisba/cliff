$:.unshift(File.dirname(__FILE__))

require 'open-uri'
require 'net/http'

begin
  require 'yajl/json'
rescue LoadError
  require 'json'
end

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

      def fetch_languages
        open("#{FP_URL}/_all_languages").read
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
      "#{FP_URL}#{@snippet_id}"
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