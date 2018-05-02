require 'discordrb'
require 'yaml'
require 'nokogiri'
require 'open-uri'
require 'terminal-table'
require 'date'

# TODO
# 	-modularise r!stats searches
 	

#load token
CONFIG = YAML.load_file('yaml/config.yaml')


# initialise bot
bot = Discordrb::Commands::CommandBot.new token: CONFIG['token'], client_id: CONFIG['client_id'], prefix: 'r!'

# rate limiting
bot.bucket :images, limit: 5, time_span: 3, delay: 3
bot.bucket :dwh, limit: 3, time_span: 60, delay: 600 


# build the string for r!commands
command_descs = Hash.new
command_descs["r!dog"] = 'Posts a random dog image.'
command_descs["r!spurdo"] = 'Posts a random spurdo image.'
command_descs["r!duck"] = 'Posts a random duck image.'
command_descs["r!stats [user] [skill]"] = "Fetches the OSRS hiscores for [user]. If no [user] is given it will use your nickname. [skill] is optional, and will only work if [user] is not specified."
command_descs["r!wiki"] = "Retrieves a 2007scape wiki link for the text following the command"

commands_string = StringIO.new
commands_string << "\u{200b}\n__List of commands:__\n"
command_descs.each do |key, value|
	commands_string << "**#{key}**\t-\t#{value}\n"
end

#set permissions
bot.set_user_permission(216784364799918081, 1)


# r!commands
# 	-gives information about public commands
bot.command(:commands, chain_usable: false) do |event|
	event.respond(commands_string.string)
end

# r!roll
bot.command(:roll) do |event|
	event.respond(rand(0..100))
end

bot.command(:roll3) do |event|
	event.respond(rand(0..1000))
end

# r!wiki
# 	-retrieves a link from the 2007scape wiki (temperamental -some url's case-sensitive
bot.command(:wiki, chain_usable: false) do |event|
	query = event.message.content.slice("r!wiki ".length..-1).gsub(' ', '_')
	search_base = "http://2007.runescape.wikia.com/wiki/"
	event.respond(search_base+query)
end


# stats array for r!stats
skills = ['overall', 'attack', 'defence', 'strength', 'hitpoints', 'ranged', 'prayer', 'magic', 'cooking', 'woodcutting', 'fletching', 'fishing', 'firemaking', 'crafting', 'smithing', 'mining', 'herblore', 'agility', 'thieving', 'slayer', 'farming', 'runecrafting', 'hunter', 'construction']

def do_search(user, stat=nil)

end

# r!stats <username> [stat_to_search]
# 	-returns an ascii representation of the total stats or a [stat_to_search]
bot.command(:stats) do |event|
	base_query = "http://services.runescape.com/m=hiscore_oldschool/hiscorepersonal.ws?user1="

	origin = event.message.content
	split_string = origin.split(' ')

	if split_string.length == 1 # if no argument given use nickname
		user_to_search = event.author.username
	else
		# looks past the command
	#removes r!stats
		user_to_search = origin.slice!(8..-1)
		if user_to_search.include? " "
			last_word = user_to_search.split(' ').slice(-1).downcase
			if skills.include? last_word
				user_to_search = user_to_search.slice(
						0..-(last_word.length+2))
				skill_to_search = last_word
				original_user_to_search = user_to_search
			end
			if user_to_search.include? " "
				user_to_search.gsub! " ", "%A0"
			end 
		end
	end
	doc = Nokogiri::HTML(open(base_query+user_to_search)) #parse jagex' hiscores
	user_to_search = user_to_search.gsub("%A0", " ")
	hiscores_div = doc.css("#contentHiscores")[0]
	if hiscores_div.at_css('div')
		event.respond('Player not found, did you spell the username correctly?')
		return
	end
	hiscores_rows = hiscores_div.css('tr')
	stat_display_rows = []
	if nil != skill_to_search
		hiscores_rows.each_with_index do |row, index|
		skill_index = skills.index(skill_to_search) + 3 
		
		stat_display_columns = []
		target_row = hiscores_rows[skill_index]	
	    	target_row.css('td').each_with_index do |column, index|

		#skip pad cell and rank cell
		next if index == 0 || index == 2
			value = column.text.strip

			stat_display_columns << value
		end
		end
		stat_display_rows << stat_display_columns
		table = Terminal::Table.new :rows => stat_display_rows
		event.respond("#{skill_to_search.capitalize} level for **#{user_to_search}**:\n```#{table}```")
			return
	end
	hiscores_rows.each_with_index do |row, index|
	    next if index < 3
	    break if index > 26
		stat_display_columns = []
	    row.css('td').each_with_index do |column, index_inner|
		next if index_inner == 0 || index_inner == 2 #skip pad cell and rank cell
		value = column.text.strip
	        stat_display_columns << value
	    end
		stat_display_rows << stat_display_columns
	end
	table = Terminal::Table.new :title => "Stats for #{user_to_search}",
		:headings => ["Skill", "Level", "Exp"], :rows => stat_display_rows
	event.respond("```#{table}```")
end


# r!tbow
# 	-tells when user will get a tbow
bot.command(:tbow, bucket: :tbow) do |event|
	# if cidna always return never
	if (event.author.id ==  154028186643070976)
		event.respond('Never')
		return
	end
	number = rand(0..3)
	case number 
		when 0
			answer = 'Never'
		when 1
			answer = 'Next raid'
		when 2
			answer = 'Within the next 10 raids'
		when 3
			answer = 'Within the next 100 raids'
	end
	event.respond(answer)
end


# r!dog
#	-posts a dog from ./dogs
bot.command(:dog, bucket: :images, rate_limit_message: 'pls no spam', description: 'Posts a random dog image', chain_usable: false) do |event|
	folder = './dogs/'
	dogs = Dir.entries(folder)
	file = open(folder+dogs[rand(2...dogs.length)], 'r')
	event.send_file(file)
end

# r!dab
#    -posts a big dab
bot.command(:dab, bucket: :images, rate_limit_message: 'pls no spam') do |event|
	file = open('./dab.png', 'r')
	event.send_file(file)
end


# r!spurdo
#  -posts a random image from ./spurdo based on the name
bot.command(:spurdo, bucket: :images, rate_limit_message: 'pls no spam', description: 'Posts a random spurdo image',
chain_usable: false) do |event|
	folder = './spurdo/'
	spurdos = Dir.entries(folder)
	file = open(folder+spurdos[rand(2...spurdos.length)], 'r')
	event.send_file(file)
end


# r!duck
# 	-posts a random duck
bot.command(:duck, bucket: :images, rate_limit_message: 'pls no spam', description: 'Posts a random duck image', chain_usable: false) do |event|
	folder = './duck/'
	ducks = Dir.entries(folder)
	file = open(folder+ducks[rand(2...ducks.length)], 'r')
	event.send_file(file)
end


=begin
# sets up points file
if file?./duck_points.txt
	duckpoints = open(./duckpoints.txt, 'rw')
else


# r!duckgame [type]
# 	-posts a random duck and awards points if guessed successfully
bot.command(:duckgame, description: 'Posts a random duck, awards a point if the user guesses the duck correctly. Ducks are:') do |event|		
	folder = './duck/'
	ducks = Dir.entries(folder)
	file = open(folder+ducks[rand(2...ducks.length)], 'r')
	guess = event.message.content.slice('r!duckgame '.length, -1)
	puts guess
	if File.basename file, extn == guess
	event.send_file(file)
end
=end


# autosaves images
=begin
bot.message(:in '313156626091737088') do |message|
	if !message.attachments.empty?
		filename = message.author+DateTime.now.strftime("%F%T")
		
	end
end
=end


# welcomes new members
bot.member_join do |event|
	bot.send_message("312958603248271363", "Hello <@#{event.user.id}>, a <@&312965121653866497> will be along shortly to give you permissions")
end


# clear a channel
bot.command(:clear, chain_usable: false, permission_level: 1) do |event|
	event.channel.prune(99)
end

bot.run

