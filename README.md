create_probes_bytag
=============

Ruby scripts for creating new probes, one for each system with a specified tag.
The original use case for this utility was to create a series of TCP probes to monitor the SSH port on EC2 instances, using the EC2 public hostname.

###Recent Updates

* Updated February 27, 2013 to fix compatability issues with ruby-1.8.7.
  At the same time, also added logic to update vs. create a probe.
* Updated February 27, 2013 10:30 PM CST, to fix an additional compatibility problem.
  Now the code has been verified on Ubuntu and mac osx; ruby 1.8.7 through 1.9.3, and a couple of versions of libcurl; verified to work with curl 7.22 and up.

###Synopsis
On the command line, you specify:
  - your apikey

  - the tag by which to filter your systems

  - optionally a TCP port to check on each of these servers. The default is port 22

  - optionally a checking interval, The default is 60 seconds

  - optionally one or more stations from which to send the TCP check. The default is all US stations.

The following steps will be carried out:

  - all systems with the specified tag that are currently not hidden or removed will be discovered

  - one probe will be defined for each tagged system found. Each new TCP probe will directed at the systems' EC2 public name, to the port specified.

  - each new probe will also be tagged with the same tag that you specified.

  - Once the script completes, you will see your new probes on the Probe Dashboard within seconds.

These ruby scripts and associated library scripts are based on :
* ruby-1.8.7 through ruby-1.9.3
* The CopperEgg API
* Ethon, which runs HTTP requests by cleanly encapsulating libcurl handling logic.

Testing has been done on ruby versions 1.8.7 through 1.9.3, and Ethon (0.5.9).

* [CopperEgg API](http://dev.copperegg.com/)
* [Ethon](https://github.com/typhoeus/ethon)

## Installation

###Clone this repository.

```ruby
git clone git://github.com/sjohnsoncopperegg/create_probes_bytag.git
```

###Run the Bundler

```ruby
bundle install
```

## Usage

```ruby
ruby create_probes_bytag.rb  APIKEY -t TAG -p PORT -i CHECKINTERVAL -s PROBESTATIONS
```
Substitute APIKEY with your CopperEgg User API key. Find it as follows:
Settings tab -> Personal Settings -> User API Access

Your command line will appear as follows:

```ruby
ruby create_probes_bytag.rb '1234567890123456' -t TAG
```

## Defaults and Options

The available options can be found by typing in the following on your command line
```ruby
ruby create_probes_bytag.rb -h
```

Today these options are

* -t, --tagstring [TAG]            Select Systems with this tag
* -p, --port [PORT]                TCP port to check
* -i, --interval [INTERVAL]        Check port every INTERVAL seconds
* -s, --station_list [STATIONS]    Stations from which to send TCP check
* -v, --verbose                    Run verbosely
* -h, --help                       Show this message


## A Common Use Case

```ruby
ruby create_probes_bytag.rb APIKEY -t TAG
```

This command line (with your APIKEY and the TAG that you are interested in) will create one TCP port 22 check for each tagged system.


##  LICENSE

(The MIT License)

Copyright © 2013 [CopperEgg Corporation](http://copperegg.com)

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the "Software"),
to deal in the Software without restriction, including without
limitation the rights to use, copy, modify, merge, publish, distribute,
sublicense, and/or sell copies of the Software, and to permit persons
to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.
