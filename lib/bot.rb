# frozen_string_literal: true

require 'telegram/bot'
require_relative 'database/processor'
require_relative 'command_handler'

# Bot class is the main entrypoint for the bot.
# It initializes the client, database processor, and command handler, and listens for incoming messages.
# When a message is received, it checks if the message is a command and calls the corresponding method
# in the command handler. Don't forget to initialize the environment variable TELEGRAM_BOT_TOKEN with your bot token.
#
# @attr_reader [Database::Processor] db_processor the database processor
# @attr_reader [CommandHandler] command_handler the command handler
# @attr_reader [Telegram::Bot::Client] client the Telegram bot client
class Bot
  attr_reader :logger, :db_processor, :command_handler, :client

  TOKEN = ENV['TELEGRAM_BOT_TOKEN']

  # Initializes the bot.
  def initialize
    @logger = init_logger

    @logger.info('Initializing the bot...')

    @db_processor = Database::Processor.new(@logger)
    @client = Telegram::Bot::Client.new(TOKEN)
    @command_handler = CommandHandler.new(client, db_processor)

    @logger.info('Bot initialized.')

    run
  end

  private

  # Initializes the logger.
  #
  # @return [Logger] the logger instance
  def init_logger
    log_file = ENV['LOG_FILE']
    File.new(log_file, 'w') unless File.exist?(log_file)

    logger = Logger.new(log_file || STDOUT)
    logger.level = ENV['LOG_LEVEL'] || Logger::INFO

    logger
  end

  # Starts the bot and listens for incoming messages.
  #
  # @return [void]
  def run
    logger.info('Starting listening for messages...')

    client.listen do |message|
      handle_message(message)
    end
  end

  # Handles an incoming message.
  #
  # @param message [Telegram::Bot::Types::Message] the incoming message
  # @return [void]
  def handle_message(message)
    command = parse_command(message)

    if command && command_handler.respond_to?(command)
      command_handler.public_send(command, message)
    else
      logger.error("Unknown command: #{message.text}") if command
    end
  end

  # Parses message and returns a method name
  #
  # @param message [Telegram::Bot::Types::Message] the incoming message
  # @return [String] the method name to call in the CommandHandler
  def parse_command(message)
    return unless command?(message)

    raw_command = message.text[1..]
    method = "handle_#{raw_command}"

    method if CommandHandler::COMMANDS.include?(raw_command)
  end

  # Checks if the message is a command
  #
  # @param message [Telegram::Bot::Types::Message] the incoming message
  # @return [Boolean] true if the message is a command, false otherwise
  def command?(message)
    message.is_a?(Telegram::Bot::Types::Message) && message.text&.start_with?('/')
  end
end
