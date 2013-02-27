#!/usr/bin/env ruby
# Copyright 2012 CopperEgg Corporation.  All rights reserved.
#
# getsystems.rb contains classes to retrieve all system information for a CopperEgg site.
#
#
#encoding: utf-8

require 'json'
require 'ethon'

class GetSystems
  def self.all(apikey,tag)
    begin
      urlstr = "https://" + apikey.to_s + ":U@api.copperegg.com/v2/revealcloud/tags/" + tag.to_s + ".json"
      params = { 'followlocation' => true, 'verbose' => false, 'ssl_verifypeer' => 0, 'headers' => { 'Accept' => "json"}, 'timeout' => 10000 }

      easy = Ethon::Easy.new
      easy.http_request( urlstr, :get, { :params => params } )
      easy.perform

      number_systems = 0
      all_systems = Array.new
      rsltcode = easy.response_code
      rslt = easy.response_body
      Ethon::Easy.finalizer(easy)
      case rsltcode
        when 200
          if valid_json?(rslt) == true
            record = JSON.parse(rslt)
            if record.is_a? Array
              number_systems = record.length
              #puts "number_systems is " + number_systems.to_s + "\n"
              if number_systems > 0
                return record
              else # no systems found
                puts "\nNo systems with this tag found. Aborting ...\n"
                return nil
              end # of 'if number_systems > 0'
            else # record is not an array
              puts "\nParse error: Expected an array. Aborting ...\n"
              return nil
            end # of 'if record.is_a?(Array)'
          else # not valid json
            puts "\nGetSystems: parse error: Invalid JSON. Aborting ...\n"
            return nil
          end # of 'if valid_json?(rslt)'
        when 404
          puts "\nGetSystems: HTTP 404 error returned. Aborting ...\n"
          return nil
        when 500...600
          puts "\nGetSystems: HTTP " +  rsltcode.to_s +  " error returned. Aborting ...\n"
          return nil
      end # of switch statement
    rescue Exception => e
      puts "Rescued in GetSystems:\n"
      p e
      return nil
    end
  end
end

