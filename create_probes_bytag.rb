#!/usr/bin/env ruby
# Copyright 2013 IDERA.  All rights reserved.
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
require './lib/createprobe'


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
  attempts = 3
  connect_try_count = 0
  pname = "CheckPort" + port.to_s + "_" + name.to_s
  probe_id = does_probe_exist(pname)
  if probe_id != nil
    update = true
    if $verbose == true
      puts "Updating probe " + pname + "\n"
    end
  else
    update = false
  end

  while connect_try_count <= attempts
    create_response = CreateProbe.tcp($APIKEY,probe_id,name,tag, addr,port,interval,stations,update)
    if create_response != nil
      if $verbose == true
        puts "\nCreateTCPProbe returned VALID\n"
      end
      return create_response
    end
    connect_try_count += 1
    if $verbose == true
      puts "\nCreateTCPProbe returned nil\n"
    end
  end
  if $verbose == true
    puts "\ncreate_tcpprobe: retries exhausted\n"
  end
  return nil
end


#
# This is the main portion of the create_probes_bytag.rb utility
#

options = GetOptions.parse(ARGV,"Usage: create_probes_bytag.rb APIKEY [options]","")

if options != nil

  $APIKEY = options.apikey
  puts "Searching for tagged systems...\n"
  allsystems = nil

  attempts = 3
  connect_try_count = 0

  while connect_try_count <= attempts
    allsystems = GetSystems.all($APIKEY,options.tag)

    if allsystems != nil
      if $verbose == true
        puts "\nGetSystems returned VALID\n"
      end
      break
    end
    connect_try_count += 1
    if $verbose == true
      puts "\GetSystems returned nil: retrying\n"
    end
  end

  if (allsystems == nil) || ((allsystems != nil) && (allsystems.count == 0))
    if $verbose == true
      puts "\GetSystems: none found; exiting\n"
      exit()
    end
  end

  $allprobes = Array.new
  $allprobes = GetProbes.all($APIKEY)

  success = 0
  fail = 0
  total = 0
  taggedsystems = Array.new

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
end
