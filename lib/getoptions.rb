#!/usr/bin/env ruby
# Copyright 2012 IDERA.  All rights reserved.
#
# getoptions.rb is a utility to parse common command line options for the Uptime Cloud Monitor addprobes utility.
#
#
#encoding: utf-8

require 'optparse'
require 'ostruct'

class GetOptions
  #
  # Return a structure containing the options.
  #
  def self.parse(args,usage_str,switch)
    # The options specified on the command line will be collected in *options*.
    # Set default values here.

    options = OpenStruct.new

    now = Time.now.utc
    options.current_time = tnow = now.to_i
    options.tag = ""
    options.apikey = ""
    options.port = 22
    options.interval = 60
    options.stations = Array.new
    options.stations =  ["dal","fre","nrk","atl"]
    options.verbose = false

    opts = OptionParser.new do |opts|
      opts.banner = usage_str

      opts.separator ""
      opts.separator "Specific options:"

      opts.on("-t", "--tagstring [TAG]" , String, "Select Systems with this tag") do |op|
        options.tag = op.to_s
      end

      opts.on("-p", "--port [PORT]" , Integer, "TCP port to check") do |op|
        options.port = op
      end

      opts.on("-i", "--interval [INTERVAL]" , Integer, "Check port every INTERVAL seconds") do |op|
        if (op == 15) || (op == 60)
          options.interval = op
        end
      end

      opts.on("-s", "--station_list [STATIONS]", Array, "Stations from which to send TCP check",
                    "all, us, global, d, f, n, a, l, t  default is us",
                    "d (Dallas), f (Fremont), n (Newark), a (Atlanta), l (London), t (Tokyo)",
                    "global (l,t), us (d,f,n,a), all (d,f,n,a,l,t)" ) do |sta|
       # print "\n"
       # p sta
       # print "\n"
        if sta == ["all"]
          options.stations = ["dal","fre","nrk","atl","lon","tok"]
        elsif sta == ["us"]
          options.stations = ["dal","fre","nrk","atl"]
        elsif  sta == ["global"]
          options.stations = ["lon","tok"]
        else
          options.stations.clear
          if sta.include?('d')
            options.stations.concat(["dal"])
          end
          if sta.include?('f')
            options.stations.concat(["fre"])
          end
          if sta.include?('n')
            options.stations.concat(["nrk"])
          end
          if sta.include?('a')
            options.stations.concat(["atl"])
          end
          if sta.include?('l')
            options.stations.concat(["lon"])
          end
          if sta.include?('t')
            options.stations.concat(["tok"])
          end
        end
      end


      # Boolean switch.
      opts.on("-v", "--verbose", "Run verbosely") do
        options.verbose = true
        $verbose = true
      end

      opts.separator ""
      opts.separator "Common options:"

      # This will print an options summary.
      opts.on_tail("-h", "--help", "Show this message") do
        puts opts
        exit
      end
    end

    if args[0] == nil
      puts usage_str + "\n"
      return nil
    else
      options.apikey = args[0]
    end
    opts.parse!(args)
    options
  end  # parse()
end  # class GetOptions
