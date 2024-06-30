# frozen_string_literal: true

require 'telegram/bot'
require 'redis'

class Bot
  attr_reader :db, :client, :commands

  TOKEN = ENV['TELEGRAM_BOT_TOKEN']
  REDIS_CONFIG = { host: 'redis', port: 6379, db: 15 }.freeze

  def initialize
    @db = Redis.new(REDIS_CONFIG)
    @client = Telegram::Bot::Client.new(TOKEN)
    @commands = {
      '/start' => method(:handle_start),
      '/add_me' => method(:handle_add_me),
      '/remove_me' => method(:handle_remove_me),
      '/go' => method(:handle_go)
    }

    run
  end

  private

  def handle_start(message)
    kb = [
      [Telegram::Bot::Types::KeyboardButton.new(text: '/add_me')],
      [Telegram::Bot::Types::KeyboardButton.new(text: '/remove_me')],
      [Telegram::Bot::Types::KeyboardButton.new(text: '/go')]
    ]
    markup = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: kb)
    client.api.send_message(chat_id: message.chat.id, text: 'Choose a command:', reply_markup: markup)
  end

  def run
    client.listen do |message|
      handle_message(message)
    end
  end

  def handle_message(message)
    return unless message.is_a?(Telegram::Bot::Types::Message)

    command = commands[message.text]
    command.call(message) if command
  end

  def handle_add_me(message)
    username = message.from.username
    chat_id = message.chat.id.to_s

    if user_in_chat?(username, chat_id)
      send_message(chat_id, "@#{username}, ты уже глиномесишься!")
    else
      add_user_to_chat(username, chat_id)
      send_message(chat_id, "Теперь @#{username} готов шерудить очком!")
    end
  end

  def handle_remove_me(message)
    username = message.from.username
    chat_id = message.chat.id.to_s

    if user_in_chat?(username, chat_id)
      remove_user_from_chat(username, chat_id)
      send_message(chat_id, "Записал @#{username} в натуралы!")
    else
      send_message(chat_id, "@#{username}, ты грязный и скучный натурал!")
    end
  end

  def handle_go(message)
    chat_id = message.chat.id.to_s
    current_chat_users = users_in_chat(chat_id)

    if current_chat_users.empty?
      send_message(chat_id, 'Никто не готов шерудить очком((((')
    else
      users_list = current_chat_users.map { |username| "@#{username}" }.join(', ')
      send_message(chat_id, "Погнали шерудить очком #{users_list}!")
    end
  end

  def user_in_chat?(username, chat_id)
    db.lrange(username, 0, -1).include?(chat_id)
  end

  def add_user_to_chat(username, chat_id)
    db.rpush(username, chat_id)
    db.persist(username)
  end

  def remove_user_from_chat(username, chat_id)
    db.lrem(username, 0, chat_id)
  end

  def users_in_chat(chat_id)
    db.keys.select { |username| user_in_chat?(username, chat_id) }
  end

  def send_message(chat_id, text)
    client.api.send_message(chat_id: chat_id, text: text)
  end
end