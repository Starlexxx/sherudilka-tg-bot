# frozen_string_literal: true

# CommandHandler class is responsible for handling incoming messages and executing the corresponding commands.
# It uses the Telegram Bot API to send messages and the Processor to interact with the database.
#
# @attr_reader [Telegram::Bot::Client] client the Telegram bot client
# @attr_reader [Database::Processor] db_processor the database processor
class CommandHandler
  attr_reader :client, :db_processor

  COMMANDS = %w[start add_me remove_me go].freeze

  # Initializes the CommandHandler.
  #
  # @param client [Telegram::Bot::Client] the Telegram bot client
  # @param db_processor [Database::Processor] the database processor
  # @return [CommandHandler] the command handler instance
  def initialize(client, db_processor)
    @client = client
    @db_processor = db_processor
  end

  # Handles the /start command. Sends a message with a keyboard of commands.
  #
  # @param message [Telegram::Bot::Types::Message] the incoming message
  # @return [void]
  KEYBOARD = [
    [
      Telegram::Bot::Types::KeyboardButton.new(text: '/add_me'),
      Telegram::Bot::Types::KeyboardButton.new(text: '/remove_me'),
      Telegram::Bot::Types::KeyboardButton.new(text: '/go')
    ]
  ]

  def handle_start(message)
    markup = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: KEYBOARD)
    client.api.send_message(chat_id: message.chat.id, text: 'Choose a command:', reply_markup: markup)
  end

  # Handles the /add_me command. Adds the user to the chat in the database and sends a confirmation message.
  #
  # @param message [Telegram::Bot::Types::Message] the incoming message
  # @return [void]
  def handle_add_me(message)
    username = message.from.username
    chat_id = message.chat.id.to_s

    if db_processor.user_in_chat?(username, chat_id)
      send_message(chat_id, "@#{username}, ты уже глиномесишься!")
    else
      db_processor.add_user_to_chat(username, chat_id)
      send_message(chat_id, "Теперь @#{username} готов шерудить очком!")
    end
  end

  # Handles the /remove_me command. Removes the user from the chat in the database and sends a confirmation message.
  #
  # @param message [Telegram::Bot::Types::Message] the incoming message
  # @return [void]
  def handle_remove_me(message)
    username = message.from.username
    chat_id = message.chat.id.to_s

    if db_processor.user_in_chat?(username, chat_id)
      db_processor.remove_user_from_chat(username, chat_id)
      send_message(chat_id, "Записал @#{username} в натуралы!")
    else
      send_message(chat_id, "@#{username}, ты грязный и скучный натурал!")
    end
  end

  # Handles the /go command. Sends a message with the list of users in the chat.
  #
  # @param message [Telegram::Bot::Types::Message] the incoming message
  # @return [void
  def handle_go(message)
    chat_id = message.chat.id.to_s
    current_chat_users = db_processor.users_in_chat(chat_id)

    if current_chat_users.empty?
      send_message(chat_id, 'Никто не готов шерудить очком((((')
    else
      users_list = current_chat_users.map { |username| "@#{username}" }.join(', ')
      send_message(chat_id, "Погнали шерудить очком #{users_list}!")
    end
  end

  private

  # Sends a message to a chat.
  #
  # @param chat_id [Integer] the ID of the chat
  # @param text [String] the text of the message
  # @return [void]
  def send_message(chat_id, text)
    client.api.send_message(chat_id: chat_id, text: text)
  end
end
