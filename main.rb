require 'discordrb'
require 'yaml'
require 'nokogiri'
require 'open-uri'

#load token
CONFIG = YAML.load_file('yaml/config.yaml')


# initialise bot
bot = Discordrb::Commands::CommandBot.new token: CONFIG['token'], client_id: CONFIG['client_id'], prefix: 'r!'


# build the string for r!commands
command_descs = Hash.new
command_descs["r!dog"] = 'Posts a random dog image'
command_descs["r!spurdo"] = 'Posts a random spurdo image'
command_descs["r!duck"] = 'Posts a random duck image'

commands_string = StringIO.new
commands_string << "\nList of commands:\n"
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

# 	TODO
# 	-Fix formatting
bot.command(:stats) do |event|
	base_query = "http://services.runescape.com/m=hiscore_oldschool/hiscorepersonal.ws?user1="
	user_to_search = event.message.content.slice("r!stats ".length..-1) #looks past the command
	doc = Nokogiri::HTML(open(base_query+user_to_search))
	hiscores_div = doc.css("#contentHiscores")[0]
	if hiscores_div.at_css('div')
		event.respond('Player not found, did you spell the username correctly?')
		return
	end
	hiscores_rows = hiscores_div.css('tr')
	stat_string = StringIO.new
	stat_string << "\u{200b}\n- **Skill** ----- **Rank** ------ **Level** ---------- **XP** ---\n"
	hiscores_rows.each_with_index do |row, index|
	    next if index < 3
	    break if index > 26
	    row.css('td').each_with_index do |column, index2|
	        if index2 == 0
				stat_string << "| "
			else
	            stat_string << '%-13.13s' % "#{column.text.strip}"
			end
	    end
	    stat_string << "|\n"
	end
	stat_string << "--------------------------------------------------\n"
	event.respond(stat_string.string)
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
