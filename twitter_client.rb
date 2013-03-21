require 'launchy'
require 'oauth'
require 'yaml'
require 'json'



class Status
  attr_accessor :user

  def initialize(user, tweet)
    @user = user
    @tweet = tweet
    post_status(@tweet)
  end

  def post_status(tweet)
    a = user.access_token.post("http://api.twitter.com/1.1/statuses/update.json", {"status" => tweet}).body

    puts "#{a}"
  end

end

class User

end

class EndUser < User
  # "consumer" in OAuth terminology means "client" in our discussion.
  CONSUMER_KEY = "zbWG8fqN1BLieFrHPPYg"
  CONSUMER_SECRET = "zRieLDh6VBpiHf7gieJrlrHw67EE2QSZg9795RC50"

  CONSUMER = OAuth::Consumer.new(
    CONSUMER_KEY, CONSUMER_SECRET, :site => "https://twitter.com")

  attr_accessor :statuses

  def initialize(name = "default")
    @name = name
    @@access_token = get_token("#{@name}.txt")
    @@access_token = request_access_token if @@access_token.nil?
    @statuses = []
  end

  def timeline
    tweets = []
    timeline = JSON.parse(user_timeline)
    timeline.each do |tweet|
      tweets << tweet["text"]
    end
    tweets
  end

  def get_tweet
    puts "give us your tweet"
    tweet = gets.chomp
  end

  def tweet(message)
    status = Status.new(self, message)

    p status ###

    @statuses << status
  end

  def access_token
    @@access_token
  end

  # ask the user to authorize the application
  def request_access_token
    # send user to twitter URL to authorize application
    request_token = CONSUMER.get_request_token
    authorize_url = request_token.authorize_url
    puts "Go to this URL: #{authorize_url}"
    # launchy is a gem that opens a browser tab for us
    Launchy.open(authorize_url)

    # because we don't use a redirect URL; user will receive an "out of
    # band" verification code that the application may exchange for a
    # key; ask user to give it to us
    puts "Login, and type your verification code in"
    oauth_verifier = gets.chomp

    # ask the oauth library to give us an access token, which will allow
    # us to make requests on behalf of this user
    access_token = request_token.get_access_token(
        :oauth_verifier => oauth_verifier)
  end

  # fetch a user's timeline
  def user_timeline
    # the access token class has methods `get` and `post` to make
    # requests in the same way as RestClient, except that these will be
    # authorized. The token takes care of the crypto for us :-)
      @@access_token.get("http://api.twitter.com/1.1/statuses/user_timeline.json").body
  end

  def get_token(token_file)
    # We can serialize token to a file, so that future requests don't need
    # to be reauthorized.

    if File.exist?(token_file)
      File.open(token_file) { |f| YAML.load(f) }
    else
      access_token = request_access_token
      File.open(token_file, "w") { |f| YAML.dump(access_token, f) }

      access_token
    end
  end


  def dm(message)
    #sends a dm to this user

  end

end


def main
  puts "what shall we call you?"
  name = gets.chomp
  user = EndUser.new(name)
  puts "select an action: 1 - Tweet || 2 - View your Timeline || 3 - DM || 4 - exit"
  action = gets.chomp.to_i

  case action
  when 1
    user.tweet(user.get_tweet)
  when 2
    puts user.timeline
  when 3

  else
    puts "thanks for coming"
  end
end

main

