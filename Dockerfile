# Use the official Ruby image from the Docker Hub
FROM ruby:3.2.2

# Install dependencies
RUN apt-get update -qq && apt-get install -y build-essential libpq-dev

# Set the working directory in the image to /app
WORKDIR /app

# Copy the Gemfile and Gemfile.lock into the image
COPY Gemfile* ./

# Install the gems
RUN bundle install

# Copy the rest of the application into the image
COPY . .

# Start the main process.
CMD ["ruby", "bin/main.rb"]