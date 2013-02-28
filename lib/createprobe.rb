#!/usr/bin/env ruby
# Copyright 2013 CopperEgg Corporation.  All rights reserved.
#
# create_probes_bytag.rb is a utility to:
#   find all systems from a site with the specified tag
#   create a TCP probe for a specified port, tagged with the same tag,
#    for each system, using the AWS public IP address
#
#
#encoding: utf-8

require 'rubygems'
require 'json'
require 'ethon'

class CreateProbe
  def self.tcp(apikey,probe_id,name,tag, addr,port,interval,stations,update)
    attempts = 3
    connect_try_count = 0
    if $debug == true
      do_verbose = true
    else
      do_verbose = false
    end
    pname = "CheckPort" + port.to_s + "_" + name.to_s
    urlstr = "https://"+apikey.to_s+":U@api.copperegg.com/v2/revealuptime/probes.json"
    sta_array = false
    addrport = addr.to_s + ":" + port.to_s
    if (stations != nil) && (stations.count >= 1)
      sta_array = true
    end

    begin
      if $verbose == true
        puts "\nGetProbes url is :\n"
        p urlstr
        print "\n"
      end

      if sta_array == true
        bdy = { "probe_desc" => pname,
                "probe_dest" => addrport,
                "type" => "TCP",
                "frequency" => interval.to_s,
                "tags" => tag,
                "stations" => stations}.to_json
      else
        bdy = { "probe_desc" => pname,
                "probe_dest" => addrport,
                "type" => "TCP",
                "frequency" => interval.to_s,
                "tags" => tag}.to_json
      end
      easy = Ethon::Easy.new
      if $verbose == true
        puts "\nCreate_probe, preparing to send API call.  JSON-encoded body is :\n"
        p bdy
        print "\n"
      end
      if update == true
        urlstr = "https://" + $APIKEY.to_s + ":U@api.copperegg.com/v2/revealuptime/probes/" + probe_id.to_s + ".json"
        if $verbose == true
          puts "url is :\n"
          p urlstr
          print "\n"
        end

        easy.http_request( urlstr, :put ,  {
            :headers => {"Content-Type" => "application/json"},
            :ssl_verifypeer => false,
            :followlocation => true,
            :verbose => do_verbose,
            :connecttimeout => 5000,
            :timeout_ms => 10000,
            :body => bdy} )
      else
        urlstr = "https://" + $APIKEY.to_s + ":U@api.copperegg.com/v2/revealuptime/probes.json"
        if $verbose == true
          puts "url is :\n"
          p urlstr
          print "\n"
        end

        easy.http_request( urlstr, :post ,  {
            :headers => {"Content-Type" => "application/json"},
            :ssl_verifypeer => false,
            :followlocation => true,
            :verbose => do_verbose,
            :connecttimeout => 5000,
            :timeout => 10000,
            :body => bdy} )
      end

      easy.perform

      rsltcode = easy.response_code
      rslt = easy.response_body
      if $verbose == true
        puts "\nCreate_probe result code is " + rsltcode.to_s + "\nResponse body is :"
        p rslt
        print "\n"
      end
      #Ethon::Easy.finalizer(easy)
      case rsltcode
        when 0
          puts "\nCreate_probe API call returned 0... timeout.\n"
          return nil
        when 200
          if valid_json?(rslt) == true
            record = JSON.parse(rslt)
            return record
          else # not valid json
            puts "\nCreate_probe parse error: Invalid JSON. Aborting ...\n"
            return nil
          end # of 'if valid_json?(rslt)'
        when 404
          puts "\nCreate_probe HTTP 404 error returned. Aborting ...\n"
          return nil
        when 500...600
          puts "\nCreate_probe HTTP " +  rsltcode.to_s +  " error returned. Aborting ...\n"
          return nil
      end # of switch statement
    rescue Exception => e
      connect_try_count += 1
      if connect_try_count > attempts
        #log "#{e.inspect}"
        raise e
        if $verbose == true
          puts "\nCreateTCPProbe: exceeded retries\n"
        end
        return nil
      end
      if $verbose == true
        puts "\nCreateTCPProbe exception: retrying\n"
      end
      sleep 0.5
    retry
    end
  end
end
