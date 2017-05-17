require 'discordrb'
require 'yaml'
require 'nokogiri'
require 'open-uri'
require 'terminal-table'

#load token
CONFIG = YAML.load_file('yaml/config.yaml')


# initialise bot
bot = Discordrb::Commands::CommandBot.new token: CONFIG['token'], client_id: CONFIG['client_id'], prefix: 'r!'


# build the string for r!commands
command_descs = Hash.new
command_descs["r!dog"] = 'Posts a random dog image'
command_descs["r!spurdo"] = 'Posts a random spurdo image'
command_descs["r!duck"] = 'Posts a random duck image'
command_descs["r!stats *user*"] = "Fetches the OSRS hiscores for *user*. If no user is given it will use your nickname"

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



# r!stats <username> [stat_to_search]
# 	-returns an ascii representation of the total stats or a [stat_to_search]
bot.command(:stats) do |event|
	base_query = "http://services.runescape.com/m=hiscore_oldschool/hiscorepersonal.ws?user1="
	if event.message.content.split(' ').length == 1 # if no argument given use nickname
		user_to_search = event.author.username.to_s
	else
		user_to_search = event.message.content.slice("r!stats ".length..-1) # looks past the command
	end
	puts base_query, user_to_search
	doc = Nokogiri::HTML(open(base_query+user_to_search))
	hiscores_div = doc.css("#contentHiscores")[0]
	if hiscores_div.at_css('div')
		event.respond('Player not found, did you spell the username correctly?')
		return
	end
	hiscores_rows = hiscores_div.css('tr')
	stat_display_rows = []
	hiscores_rows.each_with_index do |row, index|
	    next if index < 3
	    break if index > 26
		stat_display_columns = []
	    row.css('td').each_with_index do |column, index_inner|
	        next if index_inner == 0
			value = column.text.strip
	        stat_display_columns << value
	    end
		stat_display_rows << stat_display_columns
	end
	table = Terminal::Table.new :title => "Stats for #{user_to_search}",
		:headings => ["Skill", "Rank", "Level", "Exp"], :rows => stat_display_rows
	event.respond("```\u{200b}\n#{table}```")
end


# r!dog
#	-posts a dog from ./dogs
bot.command(:dog, description: 'Posts a random dog image', chain_usable: false) do |event|
	folder = './dogs/'
	dogs = Dir.entries(folder)
	file = open(folder+dogs[rand(2...dogs.length)], 'r')
	event.send_file(file)
end


# r!spurdo
#  -posts a random image from ./spurdo based on the name
bot.command(:spurdo, description: 'Posts a random spurdo image',
chain_usable: false) do |event|
	folder = './spurdo/'
	spurdos = Dir.entries(folder)
	file = open(folder+spurdos[rand(2...spurdos.length)], 'r')
	event.send_file(file)
end


# r!duck
# 	-posts a random cidnaduck
bot.command(:duck, description: 'Posts a random duck image', chain_usable: false) do |event|
	folder = './duck/'
	ducks = Dir.entries(folder)
	file = open(folder+ducks[rand(2...ducks.length)], 'r')
	event.send_file(file)
end


# welcomes new members
bot.member_join do |event|
	bot.send_message("312958603248271363", "Hello <@#{event.user.id}>, a <@&312965121653866497> or <@&312965242931904523> will be along shortly to give you permissions")
end


# clear a channel
bot.command(:clear, chain_usable: false, permission_level: 1) do |event|
	event.channel.prune(99)
end

bot.run
