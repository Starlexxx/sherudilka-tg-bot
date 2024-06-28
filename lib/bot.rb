# frozen_string_literal: true

require 'telegram/bot'

class Bot
  attr_reader :client, :users

  TOKEN = ENV['TELEGRAM_BOT_TOKEN']
  USERS_FILE = 'users.dat'

  def initialize
    @client = Telegram::Bot::Client.new(TOKEN)
    @users = load_users

    run
  end

  private

  def run
    client.listen do |message|
      handle_message(message)
    end
  end

  def handle_message(message)
    return unless message.is_a?(Telegram::Bot::Types::Message)

    case message.text
    when '/add_me'
      handle_add_me(message)
    when '/remove_me'
      handle_remove_me(message)
    when '/go'
      handle_go(message)
    end
  end

  def handle_add_me(message)
    users[message.chat.id] = message.from.username
    save_users

    client.api.send_message(chat_id: message.chat.id, text: "Теперь @#{message.from.username} готов шерудить очком!")
  end

  def handle_remove_me(message)
    users.delete(message.chat.id)
    save_users

    client.api.send_message(chat_id: message.chat.id, text: "Записал @#{message.from.username} в натуралы!")
  end

  def handle_go(message)
    current_chat_users = users.select { |chat_id, username| chat_id == message.chat.id }
    if current_chat_users.empty?
      client.api.send_message(chat_id: message.chat.id, text: 'Никто не готов шерудить очком((((')
    else
      users_list = current_chat_users.values.map { |username| "@#{username}" }.join(', ')
      client.api.send_message(chat_id: message.chat.id, text: "Погнали шерудить очком #{users_list}!")
    end
  end

  def save_users
    File.open(USERS_FILE, 'wb') do |f|
      f.write(Marshal.dump(users))
    rescue StandardError => e
      puts "Failed to save users: #{e.message}"
    end
  end

  def load_users
    return {} unless File.exist?(USERS_FILE)

    File.open(USERS_FILE, 'rb') do |f|
      Marshal.load(f)
    rescue StandardError => e
      puts "Failed to load users: #{e.message}"
      {}
    end
  end
end