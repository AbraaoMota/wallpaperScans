require 'net/http'
require 'net/https'
require 'open-uri'
require 'nokogiri'
require 'openssl'
require 'fileutils'


$minimum_url_length = 6
$https_port_num = 443
$front_page_size = 70
$max_album_size = 15
$root_dir = "#{File.expand_path(File.dirname(__FILE__))}/"
$pic_dir = "#{$root_dir}pics/"


# Argument is for name of file to save html in
def grab_html(start_url, file_name, dir)
	url = start_url
	url = URI.parse(url)

	# Establishing Connection
	puts "Establishing connection to " + start_url + "...."

	# Ensures https security
	http = Net::HTTP.new(url.host, url.port)
	http.use_ssl = true if url.port == $https_port_num
	http.verify_mode = OpenSSL::SSL::VERIFY_NONE if url.port == $https_port_num


	path = url.path
	path += "?" + url.query unless url.query.nil?
	res, data = http.get( path )
	case res
	  when Net::HTTPSuccess, Net::HTTPRedirection
	    # parse link
	    html = open(url)
			doc = Nokogiri::HTML(html)

			# Saves as html file
			puts "Loading html from " + start_url + " into #{file_name}_html ..."
			puts "placing html_file in : #{dir}#{file_name}_html"
			html_file = File.open("#{dir}#{file_name}_html", 'w')
			File.write(html_file, doc)
			return html_file
	  else
	    return "failed" + res.to_s
	end
end

def parse_html(html_file)
	in_user_submission_section = false
	file_links = Array.new($front_page_size) {String.new}
	div_counter = 0
	puts 'Parsing wallpaper links....'

	File.open(html_file, "r") do |file_handle|
	  file_handle.each_line do |current_line|
	    # if seeing the siteTable div with linklisting, then looking at
			# the user submissions in the webpage
			if current_line.include? '<div id="siteTable" class="sitetable linklisting">'
				in_user_submission_section = true;
				div_counter = 1
			end

			if in_user_submission_section
				str = find_images(current_line)
				if (str.length > $minimum_url_length)
					file_links.push(str)
				end

				if (current_line.include? "<div")
					div_counter = div_counter + 1
				end

				if (current_line.include? "</div>")
					div_counter = div_counter - 1
				end

				if (div_counter == 0)
					break
				end
			end
	  end
	end
  return file_links
end

def find_images(current_line)

	size_of_href = 5
	if current_line.include? '<p class="title">'
		href_index = current_line.index('href="')
		first_speech_mark_index = href_index + size_of_href
		second_speech_mark_index = current_line.index('" tabindex="1"')
		str = current_line[first_speech_mark_index+1..second_speech_mark_index-1]
		return str
	end
	return ""
end

def download_images(file_links, dir, in_album)
	# Make new subdir
	puts 'Making directory for pictures...'
	FileUtils.mkdir_p(dir)

	# Counter for the picture
	pic_counter = 1

	# Album counter
	albums = 1

	# Loop through the links of the files, download them into new subdir
	file_links.each{ |file_link|
		if (file_link.include? 'http')
			if (!in_album)
				if ((file_link.include? 'imgur') && ((file_link.include? "/a/") || (file_link.include? "/t/wallpaper")))
					file_link = handle_imgur_album(file_link, albums)
					albums += 1
					next
				# Case for imgur single pic
				elsif ((file_link.include? 'imgur') && (!file_link.include? ".jpg"))
					file_link = handle_imgur_single_pic(file_link)
				end
			end

			# Ensures https security
			file_link = URI.encode(file_link)
			file_link = URI.parse(file_link)
			http = Net::HTTP.new(file_link.host, file_link.port)
			http.use_ssl = true if file_link.port == $https_port_num
			http.verify_mode = OpenSSL::SSL::VERIFY_NONE if file_link.port == $https_port_num
			path = file_link.path
			path += "?" + file_link.query unless file_link.query.nil?
			res, data = http.get( path )


			case res
				  when Net::HTTPSuccess, Net::HTTPRedirection
							File.open("#{dir}/#{pic_counter}.jpg", 'wb') do |f|
						  	f.write open(file_link.to_s).read
						 		pic_counter += 1
						end
				  else
						puts file_link
						puts "failed" + res.to_s
			end

		end
 	}
end

def handle_imgur_single_pic(file_link)
	  # Removes '/new' link tag
	  if (file_link.include? "/new")
			file_link.slice!("/new")
		end
		# Removes '/gallery' link tag
		if (file_link.include? "/gallery")
			file_link.slice!("/gallery")
		end

		return file_link << ".jpg"
end

def parse_albums(albums)
	in_user_submission_section = false
	file_links = Array.new($max_album_size) {String.new}
	puts "Parsing wallpaper links for album at #{$pic_dir}#{albums}_html"
	puts "Opening: #{$pic_dir}#{albums}_html"
	File.open("#{$pic_dir}#{albums}_html", "r") do |file_handle|
		file_handle.each_line do |current_line|
			if current_line.include? 'meta property="og:image"'
				in_user_submission_section = true;
			end
			if current_line.include? '</head>'
				in_user_submission_section = false;
			end
			if in_user_submission_section
				str = find_album_images(current_line)
				if (str.length > $minimum_url_length)
					file_links.push(str)
				end
			end
		end
	end
	return file_links
end

def find_album_images(current_line)
	size_of_content = 9
	if ((current_line.include? 'content="') && (current_line.include? '>'))
		content_index = current_line.index('content="')
		first_speech_mark_index = content_index + size_of_content
		second_speech_mark_index = current_line.index('>')

		if (first_speech_mark_index == nil || second_speech_mark_index == nil)
			return ""
		end

		str = current_line[first_speech_mark_index..second_speech_mark_index-1]
		return str
	end
	return ""
end

def handle_imgur_album(file_link, albums)
	# Place html of page into equivalent file
	file = grab_html(file_link, "#{albums}", $pic_dir)
	links = parse_albums(albums)
	download_images(links, "#{$pic_dir}/#{albums}", true)
	return file_link
end


# execute it all
file = grab_html('https://www.reddit.com/r/wallpapers/?count=25&after=t3_42jxly', "reddit", $root_dir)
links = parse_html(file)
download_images(links, "#{$pic_dir}", false)
