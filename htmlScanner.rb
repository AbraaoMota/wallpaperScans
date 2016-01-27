require 'net/http'
require 'net/https'
require 'open-uri'
require 'nokogiri'
require 'openssl'
require 'fileutils'

$download_url = "https://www.reddit.com/r/wallpapers/"
$url_is_complex = $download_url.include?("/?")
$url_based_dir = $url_is_complex ?
								 $download_url[$download_url.index("/r/")+3..$download_url.index("/?")] << $download_url[-9..-1]
								 :
								 "r_" << $download_url[$download_url.index("/r/")+3..-2]
$minimum_url_length = 6
$https_port_num = 443
$front_page_size = 70
$max_album_size = 15
$time = Time.new
$today =  $time.strftime("%d-%m-%Y")
$root_dir = "#{File.expand_path(File.dirname(__FILE__))}/"
$pic_dir = "#{$root_dir}pics/#{$today}/#{$url_based_dir}"

# Argument is for name of file to save html in
def grab_html(start_url, file_name, dir)
	url = start_url
	url = URI.parse(url)

	# Establishing Connection
	puts "\nEstablishing connection to #{start_url} ....\n\n"

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
			puts "Loading html from #{start_url} into #{file_name}_html ...\n\n"

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
	puts "Parsing wallpaper links....\n\n"

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
	html_file.close
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
	puts "Making directory #{dir} for " + (in_album ? "album " : "") + "pictures...\n\n"
	FileUtils.mkdir_p(dir)

	# Counter for the picture
	pic_counter = 1

	# Album counter
	albums = 1

	# Png support bool
	is_png = false

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

			if (file_link.include? "png")
				is_png = true;
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
						if (is_png)
							File.open("#{dir}/#{pic_counter}.png", 'wb') do |f|
						  	f.write open(file_link.to_s).read
						 		pic_counter += 1
							end
							is_png = false;
						else
							File.open("#{dir}/#{pic_counter}.jpg", 'wb') do |f|
						  	f.write open(file_link.to_s).read
						 		pic_counter += 1
							end
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

def parse_albums(file, albums)
	in_user_submission_section = false
	file_links = Array.new($max_album_size) {String.new}
	puts "Parsing wallpaper links for album at #{$pic_dir}#{albums}_html ....\n\n"
	File.open(file, "r") do |file_handle|
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
  file.close
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
	links = parse_albums(file, albums)
	download_images(links, "#{$pic_dir}/#{albums}", true)
	return file_link
end


# execute it all
file = grab_html($download_url, "reddit", $root_dir)
links = parse_html(file)
download_images(links, "#{$pic_dir}", false)
puts "Deleting all '_html' files\n\n"
`DEL /S /F *_html.*`
puts "Finished, enjoy the pictures!\n"
