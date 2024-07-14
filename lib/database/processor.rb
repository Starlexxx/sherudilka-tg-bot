# frozen_string_literal: true

require 'redis'

# Database module contains classes for interacting with the database.
module Database
  # Processor class is responsible for handling all the database operations.
  # It uses the Redis client to interact with the Redis database.
  #
  # @attr_reader [Redis] db the Redis client
  class Processor
    attr_reader :logger, :db

    # Initializes the Processor.
    #
    # @param logger [Logger] the logger instance
    # @return [Processor] the database processor instance
    def initialize(logger)
      @logger = logger

      logger.info(
        "Initializing the database processor with the configuration: " \
          "#{ENV['REDIS_HOST']}:#{ENV['REDIS_PORT']}"
      )

      @db = Redis.new(host: ENV['REDIS_HOST'], port: ENV['REDIS_PORT'])
      if @db.ping != 'PONG'
        message = 'Could not connect to the database with the provided configuration: ' \
          "#{ENV['REDIS_HOST']}:#{ENV['REDIS_PORT']}}"

        logger.error(message)

        raise(ConnectionError, message)
      end
    end

    # Checks if a user is in a chat.
    #
    # @param username [String] the username of the user
    # @param chat_id [String] the ID of the chat
    # @return [Boolean] true if the user is in the chat, false otherwise
    def user_in_chat?(username, chat_id)
      logger.info("DatabaseProcessor: #{Time.now} - Checking if user #{username} is in chat #{chat_id}")
      db.lrange(username, 0, -1).include?(chat_id)
    end

    # Adds a user to a chat.
    #
    # @param username [String] the username of the user
    # @param chat_id [String] the ID of the chat
    # @return [void]
    def add_user_to_chat(username, chat_id)
      logger.info("DatabaseProcessor: #{Time.now} - Adding user #{username} to chat #{chat_id}")
      db.rpush(username, chat_id)
      logger.info("DatabaseProcessor: #{Time.now} - User #{username} added to chat #{chat_id}")
    end

    # Removes a user from a chat.
    #
    # @param username [String] the username of the user
    # @param chat_id [String] the ID of the chat
    # @return [void]
    def remove_user_from_chat(username, chat_id)
      logger.info("DatabaseProcessor: #{Time.now} - Removing user #{username} from chat #{chat_id}")
      db.lrem(username, 0, chat_id)
      logger.info("DatabaseProcessor: #{Time.now} - User #{username} removed from chat #{chat_id}")
    end

    # Gets the users in a chat.
    #
    # @param chat_id [String] the ID of the chat
    # @return [Array<String>] the usernames of the users in the chat
    def users_in_chat(chat_id)
      db.keys.select { |username| user_in_chat?(username, chat_id) }
    end
  end
end
