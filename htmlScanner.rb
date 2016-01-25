require 'net/http'
require 'net/https'
require 'open-uri'
require 'nokogiri'
require 'openssl'
require 'fileutils'


$minimumURLLength = 6
$HTTPSPortNum = 443
$frontPageSize = 70


def grab_html
	# Defining url
	startURL = 'https://www.reddit.com/r/wallpapers'
	url = startURL
	url = URI.parse(url)

	# Establishing Connection
	puts "Establishing connection to " + startURL + "...."

	# Ensures https security
	http = Net::HTTP.new(url.host, url.port)
	http.use_ssl = true if url.port == $HTTPSPortNum
	http.verify_mode = OpenSSL::SSL::VERIFY_NONE if url.port == $HTTPSPortNum


	path = url.path
	path += "?" + url.query unless url.query.nil?
	res, data = http.get( path )
	case res
	  when Net::HTTPSuccess, Net::HTTPRedirection
	    # parse link
	    html = open(url)
			doc = Nokogiri::HTML(html)

			# Saves html into xml file
			puts "Loading html from " + startURL + " into htmlFile ..."
			htmlFile = File.open('html', 'w')
			File.write(htmlFile, doc)
			return htmlFile
	  else
	    return "failed" + res.to_s
	end
end


def parse_html (htmlFile)
inUserSubmissionSection = false
fileLinks = Array.new($frontPageSize) {String.new}
divCounter = 0
puts 'Parsing wallpaper links....'

	File.open(htmlFile, "r") do |file_handle|
	  file_handle.each_line do |currentLine|
	    # if seeing the siteTable div with linklisting, then looking at
			# the user submissions in the webpage
			if currentLine.include? '<div id="siteTable" class="sitetable linklisting">'
				inUserSubmissionSection = true;
				divCounter = 1
			end

			if inUserSubmissionSection
				str = findImages(currentLine)
				if (str.length > $minimumURLLength)
					#puts "This is added" + str
					fileLinks.push(str)
				end

				if (currentLine.include? "<div")
					divCounter = divCounter + 1
				end

				if (currentLine.include? "</div>")
					divCounter = divCounter - 1
				end

				if divCounter == 0
					break
				end
			end
	  end
	end
  return fileLinks
end

def findImages(currentLine)

	sizeOfHrefStr = 5
	if currentLine.include? '<p class="title">'
		hrefIndex = currentLine.index('href="')
		firstSpeechMarkIndex = hrefIndex + sizeOfHrefStr
		secondSpeechMarkIndex = currentLine.index('" tabindex="1"')
		str = currentLine[firstSpeechMarkIndex+1..secondSpeechMarkIndex-1]
		return str
	end
	return ""
end


def downloadImages(fileLinks)
	# Make new subdir
	puts 'Making directory for pictures...'
	FileUtils.mkdir_p("#{File.expand_path(File.dirname(__FILE__))}/pics/")

	# Counter for the picture
	picCounter = 1

	# Loop through the links of the files, download them into new subdir
	fileLinks.each{ |fileLink|
		# Boolean for Albums, if so, download all pictures into subdir
		isAlbum = 0

		if (fileLink.include? 'http')
			# Case for imgur albums
			if ((fileLink.include? 'imgur') && ((fileLink.include? "/a/") || (fileLink.include? "/t/wallpaper")))
				#puts fileLink
				fileLink = handleImgurAlbums(fileLink)
				isAlbum = 1
				#puts fileLink
			# Case for imgur single pic
			elsif ((fileLink.include? 'imgur') && (!fileLink.include? ".jpg"))
				fileLink = handleImgurSinglePic(fileLink)
				#puts fileLink
			end

			# Ensures https security
			fileLink = URI.parse(fileLink)
			http = Net::HTTP.new(fileLink.host, fileLink.port)
			http.use_ssl = true if fileLink.port == $HTTPSPortNum
			http.verify_mode = OpenSSL::SSL::VERIFY_NONE if fileLink.port == $HTTPSPortNum
			path = fileLink.path
			path += "?" + fileLink.query unless fileLink.query.nil?
			res, data = http.get( path )


			case res
				  when Net::HTTPSuccess, Net::HTTPRedirection
						puts "Downloading image number #{picCounter}"
						File.open("#{File.expand_path(File.dirname(__FILE__))}/pics/#{picCounter}.jpg", 'wb') do |f|
							#puts fileLink
					  	f.write open(fileLink.to_s).read
					 		picCounter += 1
						end
					#when isAlbum
						# Download pics from imgur album

				  else
						puts fileLink
						puts "failed" + res.to_s
			end

		end
 	}
end


def handleImgurSinglePic(fileLink)
	  if (fileLink.include? "/new")
			# Removes '/new' link tag
			#fileLink = fileLink[0..-5]
			fileLink.slice!("/new")
		end
		if (fileLink.include? "/gallery")
			fileLink.slice!("/gallery")
			#puts fileLink
		end

		return fileLink << ".jpg"
end

def handleImgurAlbums(fileLink)
	# TODO: Write this method
	return fileLink
end



# execute it all
file = grab_html
links = parse_html(file)
downloadImages(links)
