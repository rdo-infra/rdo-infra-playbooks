# Adapted as a filter from
# https://github.com/sensu-plugins/sensu-plugin/blob/master/lib/sensu-handler.rb

require 'net/http'
require 'uri'
require 'json'
require 'sensu-plugin/utils'

module Sensu::Extension
  class DisabledOrSilenced < Filter
    include Sensu::Plugin::Utils

    STOP_PROCESSING  = 0
    ALLOW_PROCESSING = 1

    def name
      'filter_disabled_or_silenced'
    end

    def description
      "Basic filter that stops processing when check alerts are disabled or "\
      "if any relevant silence stashes are found."
    end

    def run(event)
      begin
        rc, msg = filter(event)
        yield msg, rc
      rescue => e
        # filter crashed - let's pass this on to handler
        yield e.message, ALLOW_PROCESSING, "disabled_or_silenced filter error"
      end
    end

    def api_settings
      @api_settings ||= if ENV['SENSU_API_URL']
        uri = URI(ENV['SENSU_API_URL'])
        {
          'host' => uri.host,
          'port' => uri.port,
          'user' => uri.user,
          'password' => uri.password
        }
      else
        settings['api']
      end
    end

    def api_request(method, path, &blk)
      if api_settings.nil?
        raise "api.json settings not found."
      end
      domain = api_settings['host'].start_with?('http') ? api_settings['host'] : 'http://' + api_settings['host']
      uri = URI("#{domain}:#{api_settings['port']}#{path}")
      req = net_http_req_class(method).new(uri)
      if api_settings['user'] && api_settings['password']
        req.basic_auth(api_settings['user'], api_settings['password'])
      end
      yield(req) if block_given?
      res = Net::HTTP.start(uri.hostname, uri.port, :use_ssl => uri.scheme == 'https') do |http|
        http.request(req)
      end
      res
    end

    def stash_exists?(path)
      api_request(:GET, '/stash' + path).code == '200'
    end

    def filter(event)
      ###
      # Stop processing if alerts are disabled for this check
      ###
      if event[:check][:alert] == false
        return STOP_PROCESSING, "alert disabled"
      end

      ###
      # Stop processing if there is a relevant silence stash
      ###
      stashes = [
        ['client', '/silence/' + event[:client][:name]],
        ['check', '/silence/' + event[:client][:name] + '/' + event[:check][:name]],
        ['check', '/silence/all/' + event[:check][:name]]
      ]
      stashes.each do |(scope, path)|
        begin
          timeout(5) do
            if stash_exists?(path)
              return STOP_PROCESSING, "alert silenced"
            end
          end
        rescue Errno::ECONNREFUSED
          puts 'connection refused attempting to query the sensu api for a stash'
          return false
        rescue Timeout::Error
          puts 'timed out while attempting to query the sensu api for a stash'
          return false
        end
      end
    end
  end
end
