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
require 'multi_json'
require 'pp'
require 'ethon'
require './lib/getoptions'
require './lib/getsystems'
require './lib/getprobes'

$APIKEY = ""
$verbose = false
$debug = false
$allprobes = nil

def valid_json? json_
  begin
    JSON.parse(json_)
    return true
  rescue Exception => e
    return false
  end
end

def does_probe_exist(probe_desc)
  begin
    if $allprobes != nil

      num_probes = $allprobes.length
      num = 0

      while num < num_probes
        h = $allprobes[num]
        if h["probe_desc"] == probe_desc
          return h["id"]
        end
        num = num + 1
      end
    end
    return nil
  rescue Exception => e
    puts "\ndoes_probe_exist exception ... error is " + e.message + "\n"
    return nil
  end
end

def filter_ontag(allsystems)
  begin
    num_systems = allsystems.length

    numwithtag = 0
    withtag = Array.new
    num = 0

    while num < num_systems
      h = allsystems[num]
      if (h["state"] == 2) && (h["hidden"] == false) && (h["published_rc_version"] != "")
        ha = h["attrs"]
        if ( ha["hostname"] != nil) && (ha["aws_public_ipv4"] != nil) && (ha["aws_public_hostname"] != nil)
          withtag[numwithtag] = Hash.new
          withtag[numwithtag]["hostname"] = ha["hostname"]
          withtag[numwithtag]["aws_public_ipv4"] = ha["aws_public_ipv4"]
          withtag[numwithtag]["aws_public_hostname"] = ha["aws_public_hostname"]
          numwithtag = numwithtag + 1
        end
      end
      num = num + 1
    end
    return withtag
  rescue Exception => e
    puts "\nfilter_ontag exception ... error is " + e.message + "\n"
    return nil
  end
end

def create_tcpprobe(name,tag, addr,port,interval,stations)

  update = false
  pname = "CheckPort" + port.to_s + "_" + name.to_s

  probe_id = does_probe_exist(pname)
  if probe_id != nil
    update = true
    if $verbose == true
      puts "Updating probe " + pname + "\n"
    end
  end
  begin
    sta_array = false
    addrport = addr.to_s + ":" + port.to_s

    if (stations != nil) && (stations.count >= 1)
    	sta_array = true
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
      puts "JSON-encoded body is :\n"
      p bdy
      print "\n"
    end
    if update == true
      urlstr = "https://" + $APIKEY.to_s + ":U@api.copperegg.com/v2/revealuptime/probes/" + probe_id.to_s + ".json"
      easy.http_request( urlstr, :put ,  {
 	        :headers => {"Content-Type" => "application/json"},
          :ssl_verifypeer => false,
          :followlocation => true,
          :verbose => false,
          :timeout => 10000,
	        :body => bdy} )
    else
      urlstr = "https://" + $APIKEY.to_s + ":U@api.copperegg.com/v2/revealuptime/probes.json"
      easy.http_request( urlstr, :post ,  {
          :headers => {"Content-Type" => "application/json"},
          :ssl_verifypeer => false,
          :followlocation => true,
          :verbose => false,
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
    Ethon::Easy.finalizer(easy)
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
    puts "Rescued in Create_probe:\n"
    p e
    return nil
  end
end


#
# This is the main portion of the create_probes_bytag.rb utility
#

options = GetOptions.parse(ARGV,"Usage: create_probes_bytag.rb APIKEY [options]","")

if options != nil

  $APIKEY = options.apikey
  puts "Searching for tagged systems...\n"
  allsystems = Array.new
  allsystems = GetSystems.all($APIKEY,options.tag)

  if allsystems != nil
    taggedsystems = Array.new
    success = 0
    fail = 0
    total = 0
    $allprobes = Array.new
    $allprobes = GetProbes.all($APIKEY)

    taggedsystems = filter_ontag(allsystems)
    if taggedsystems != nil
      taggedsystems.each do |hsh|
        total = total + 1
        r = create_tcpprobe(hsh["hostname"],options.tag,hsh["aws_public_hostname"],options.port,options.interval,options.stations)
        if r != nil
          success = success + 1
        else
          fail = fail + 1
        end
      end
      puts "\nOperation Completed\n"
      puts total.to_s + " systems found tagged with " + options.tag + "\n"
      puts success.to_s + " probes created or updated\n"
      if fail != 0
        puts fail.to_s + " probe creation attempts failed\n"
      end
    else
      puts "No systems found\n"
    end
  else
    puts "No systems found\n"
  end # of 'if allsystems != nil'
end
