# wallpaperScans
This directory contains a simple script in Ruby that scans through the front-page of the wallpapers subreddit and downloads all of those in the 1st page. Places them in a subdirectory called pics, relative to the position of the script.




# Use
The following instructions are for use and setup on windows.

You may need to follow these steps to avoid an SSL error:
https://gist.github.com/fnichol/867550

As mentioned in the link, it's useful to set the environment variables for more than a 1-time use.
Go to Control Panel -> System & Security -> System -> Advanced System Settings -> Environment Variables -> New -> 
Name: SSL_CERT_FILE, Value = C:\RailsInstaller\cacert.pem


This was my first real attempt at using Ruby on my own. Thanks to the Nokogiri gem for the help with HTML connections & for fNichol for the very useful link above.
