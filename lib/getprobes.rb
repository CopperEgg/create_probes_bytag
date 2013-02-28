#!/usr/bin/env ruby
# Copyright 2012,2013 CopperEgg Corporation.  All rights reserved.
#
# getprobes.rb contains classes to retrieve all probe information for a CopperEgg site.
#
#
#encoding: utf-8

require 'json'
require 'ethon'

class GetProbes
  def self.all(apikey)
    attempts = 3
    connect_try_count = 0

      urlstr = "https://"+apikey.to_s+":U@api.copperegg.com/v2/revealuptime/probes.json"
      if $verbose == true
        puts "\nGetProbes url is :\n"
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

      number_probes = 0
      all_probes = Array.new

      case easy.response_code
        when 0
          if $verbose == true
            puts "\nGetProbes: CURL timeout error.\n"
          end
          return nil
        when 200
          if valid_json?(easy.response_body) == true
            record = JSON.parse(easy.response_body)
            if record.is_a? Array
              number_probes = record.length
              if $verbose == true
                puts "\nGetProbes: found " + number_proves.to_s + " probes.\n"
              end
              return record
            else # record is not an array
              puts "\nGetProbes: Parse error: Expected an array.\n"
              return nil
            end # of 'if record.is_a?(Array)'
          else # not valid json
            puts "\nGetProbes: parse error: Invalid JSON.\n"
            return nil
          end # of 'if valid_json?(easy.response_body)'
        when 404
          puts "\nGetProbes: HTTP 404 error returned.\n"
          return nil
        when 500...600
          if $verbose == true
            puts "\nGetProbes: HTTP " +  easy.response_code.to_s +  " error returned.\n"
          end
          return nil
      end # of switch statement
    rescue Exception => e
      connect_try_count += 1
      if connect_try_count > attempts
        #log "#{e.inspect}"
        raise e
        if $verbose == true
          puts "\nGetProbes: exceeded retries\n"
        end
        return nil
      end
      if $verbose == true
        puts "\nGetProbes exception: retrying\n"
      end
      sleep 0.5
    retry
    end  # of begin rescue end
  end  # of 'def self.all(apikey)'
end  #  of class
