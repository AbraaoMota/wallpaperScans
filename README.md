# wallpaperScans
This directory contains a simple script in Ruby that scans through the front-page of the wallpapers subreddit on reddit and downloads all of those in the 1st page. Places them in a subdirectory called pics, relative to the position of the script.
Can also work in theory for other subreddits that are mainly for user submitted pictures.


# Use
The following instructions are for use and setup on windows.

RubyInstaller:
http://rubyinstaller.org/

Installation of the nokogiri gem:
http://www.nokogiri.org/tutorials/installing_nokogiri.html#windows

You may need to follow these steps to avoid an SSL error:
https://gist.github.com/fnichol/867550

As mentioned in the link, it's useful to set the environment variables for more than a 1-time use.
Go to Control Panel -> System & Security -> System -> Advanced System Settings -> Environment Variables -> New -> 
Name: SSL_CERT_FILE, Value = C:\RailsInstaller\cacert.pem

Once setup finished, just go to directory and call htmlScanner.rb on the command line.

This was my first real attempt at using Ruby on my own. Thanks to the Nokogiri gem for the help with HTML connections & for fNichol for the very useful link above.


### Untested ###
May work in other environments, see https://www.ruby-lang.org/en/downloads/ for UNIX based systems

#TODO:
1. Setup https connections when downloading pictures too
2. Allow for nice downloads of imgur albums
3. GUI / Picture selector
4. Package into an .exe
