#!/usr/bin/env ruby
# Copyright 2012,2013 IDERA.  All rights reserved.
#
# getsystems.rb contains classes to retrieve all system information for a Uptime Cloud Monitor site.
#
#
#encoding: utf-8

require 'json'
require 'ethon'

class GetSystems
  def self.all(apikey,tag)
    attempts = 3
    connect_try_count = 0
    urlstr = "https://" + apikey.to_s + ":U@api.copperegg.com/v2/revealcloud/tags/" + tag.to_s + ".json"
    if $verbose == true
      puts "\nGetSystems url is :\n"
      p urlstr
      print "\n"
    end
    if $debug == true
      do_verbose = true
    else
      do_verbose = false
    end

    begin

      easy = Ethon::Easy.new
      easy.http_request( urlstr, :get, {
        :headers => {"Content-Type" => "application/json"},
        :ssl_verifypeer => false,
        :followlocation => true,
        :verbose => do_verbose,
        :connecttimeout => 5000,
        :timeout => 10000
      } )
      easy.perform

      number_systems = 0
      all_systems = Array.new
      rsltcode = easy.response_code
      rslt = easy.response_body

      #Ethon::Easy.finalizer(easy)
      case rsltcode
        when 0
          if $verbose == true
            puts "\nGetSystems: rsltcode is 0 ... timeout\n"
          end
          return nil
        when 200
          if valid_json?(rslt) == true
            record = JSON.parse(rslt)
            if $verbose == true
              puts "\nGetSystems:  valid_json returned true\n"
              p record
              print "\n\n"
            end

            if record.is_a? Array
              number_systems = record.length
              if $verbose == true
                puts "\nFound " + number_systems.to_s + " tagged systems\n"
              end
              return record
            else # record is not an array
              puts "\nGetSystems: Parse error: Expected an array.\n"
              return nil
            end # of 'if record.is_a?(Array)'
          else # not valid json
            puts "\nGetSystems: parse error: Invalid JSON.\n"
            return nil
          end # of 'if valid_json?(rslt)'
        when 404
          puts "\nGetSystems: HTTP 404 error returned.\n"
          return nil
        when 500...600
          if $verbose == true
            puts "\nGetSystems: HTTP " +  rsltcode.to_s +  " error returned.\n"
          end
          return nil
      end # of switch statement
    rescue Exception => e
      connect_try_count += 1
      if connect_try_count > attempts
        #log "#{e.inspect}"
        raise e
        if $verbose == true
          puts "\nGetSystems: exceeded retries\n"
        end
        return nil
      end
      if $verbose == true
        puts "\nGetSystems exception: retrying\n"
      end
      sleep 0.5
    retry
    end
  end
end

