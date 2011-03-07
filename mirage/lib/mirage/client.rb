require 'uri'
require 'mechanize'
require 'open-uri'

class Mirage
  class File
    def initialize response
      @response = response
    end

    def save_as path
      @response.save_as(path)
    end
  end


  class Client
    def initialize url="http://localhost:7001/mirage"
      @uri = URI.parse(url)
    end

    def get endpoint, params={}
      http_get("/get/#{endpoint}", params)
    end

    def set endpoint, params={}
      http_post("/set/#{endpoint}", params)
    end

    def peek response_id
      http_get("/peek/#{response_id}")
    end

    def clear thing=nil, endpoint=nil
      if endpoint.nil?
        http_get("/clear")
      else
          if thing.nil?
          http_get("/clear/#{endpoint}")
        else
          http_get("/clear/#{thing}/#{endpoint}")
        end

      end
    end

    def check response_id
      http_get("/check/#{response_id}")
    end

    def snapshot
      http_post("/snapshot")
    end

    def rollback
      http_post("/rollback")
    end

    def running?
      !http_get('').is_a?(Errno::ECONNREFUSED)
    end

    def load_defaults
      http_post('/load_defaults')
    end


    private
    def http_get endpoint, params={}
      if params[:body]
        response = Net::HTTP.start(@uri.host, @uri.port) do |http|
          request = Net::HTTP::Get.new("#{@uri.path}/#{endpoint}")
          request.body=params[:body]
          http.request(request)
        end

        def response.code
          @code.to_i
        end

      else
        response = using_mechanize do |browser|
          browser.get("#{@uri}#{endpoint}", params)
        end
      end

      return response.code == 200 ? response.body : response if response.is_a?(Mechanize::Page) || response.is_a?(Net::HTTPOK)
      return File.new(response) if response.is_a?(Mechanize::File)
      response
    end

    def http_post path, params={}
      response = using_mechanize do |browser|
        browser.post("#{@uri}#{path}", params)
      end
      response.code == 200 ? response.body : response
    end

    def using_mechanize
      begin
        browser = Mechanize.new
        browser.keep_alive = false
        response = yield browser

        def response.code
          @code.to_i
        end
      rescue Exception => e
        response = e

        def response.code
          self.response_code.to_i
        end

        def response.body
          ""
        end
      end
      response
    end

  end


end