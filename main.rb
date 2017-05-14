require 'discordrb'
require 'yaml'

#load token
CONFIG = YAML.load_file('yaml/config.yaml')


# initialise bot
bot = Discordrb::Commands::CommandBot.new token: CONFIG['token'], client_id: CONFIG['client_id'], prefix: 'r!'

#set permissions
bot.set_user_permission(216784364799918081, 1)


# r!commands
# 	-gives information about public commands



# r!dog
#	-posts a dog from ./dogs
bot.command :dog do |event|
	folder = './dogs/'
	dogs = Dir.entries(folder)
	file = open(folder+dogs[rand(0...dogs.length)], 'r')
	event.send_file(file)
end

# r!spurdo
#  -posts a random image from ./spurdo based on the name
bot.command :spurdo do |event|
	file = open("spurdo/#{rand(1...10)}.png", 'r')
	event.send_file(file)
end


# welcomes new members
bot.member_join do |event|
	bot.send_message("312958603248271363", "Hello <@#{event.user.id}>, mention a Lad or Lass to get permissions")
end


# clear a channel
bot.command(:clear, permission_level: 1) do |event|
	event.channel.prune(99)
end

bot.run
