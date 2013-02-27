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
    num_probes = $allprobes.length
    num = 0

    while num < num_probes
      h = $allprobes[num]
      if h["probe_desc"] == probe_desc
        return h["id"]
      end
      num = num + 1
    end
    return nil
  rescue Exception => e
    puts "does_probe_exist exception ... error is " + e.message + "\n"
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
    puts "filter_ontag exception ... error is " + e.message + "\n"
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
    stastring = ""
    bdy = "probe_desc=" + pname + "&probe_dest=" + addr.to_s + ":" + port.to_s + "&type=TCP&frequency=" + interval.to_s + "&tags=" + tag
    if stations != nil
      if stations.count >= 1
        stastring = stations[0]
        ind = 1
        while ind < stations.count
          stastring = stastring + "," + stations[ind]
          ind = ind + 1
        end
        bdy = bdy + "&stations=" + stastring.to_s
      end
    end
    params = { 'followlocation' => true, 'verbose' => false, 'ssl_verifypeer' => 0, 'headers' => { 'Accept' => "json"}, 'timeout' => 10000 }
    easy = Ethon::Easy.new

    if update == true
      urlstr = "https://" + $APIKEY.to_s + ":U@api.copperegg.com/v2/revealuptime/probes/" + probe_id.to_s + ".json"
      easy.http_request( urlstr, :put ,  { :params => params, :body => bdy} )
    else
      urlstr = "https://" + $APIKEY.to_s + ":U@api.copperegg.com/v2/revealuptime/probes.json"
      easy.http_request( urlstr, :post ,  { :params => params, :body => bdy} )
    end

    easy.perform

    rsltcode = easy.response_code
    rslt = easy.response_body
    if $verbose == true
      puts "result code is " + rsltcode.to_s + "\nResponse body is :"
      p rslt
      print "\n"
    end
    Ethon::Easy.finalizer(easy)
    case rsltcode
      when 200
        if valid_json?(rslt) == true
          record = JSON.parse(rslt)
          return record
        else # not valid json
          puts "\nAddProbe: parse error: Invalid JSON. Aborting ...\n"
          return nil
        end # of 'if valid_json?(rslt)'
      when 404
        puts "\nAddProbe: HTTP 404 error returned. Aborting ...\n"
        return nil
      when 500...600
        puts "\nAddProbe: HTTP " +  rsltcode.to_s +  " error returned. Aborting ...\n"
        return nil
    end # of switch statement
  rescue Exception => e
    puts "Rescued in AddProbe:\n"
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
  taggedsystems = Array.new
  success = 0
  fail = 0
  total = 0

  $allprobes = Array.new
  $allprobes = GetProbes.all($APIKEY)

  if allsystems != nil
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