require 'launchy'
require 'oauth'
require 'yaml'
require 'json'
require 'addressable/uri'

CONSUMER_KEY = "zbWG8fqN1BLieFrHPPYg"
CONSUMER_SECRET = "zRieLDh6VBpiHf7gieJrlrHw67EE2QSZg9795RC50"

CONSUMER = OAuth::Consumer.new(
  CONSUMER_KEY, CONSUMER_SECRET, :site => "https://twitter.com")

class Status
  attr_reader :user, :tweet

  def initialize(user, tweet)
    @user = user
    @tweet = tweet
  end

  def post_status
    a = EndUser.access_token.post("http://api.twitter.com/1.1/statuses/update.json", {"status" => @tweet}).body
  end
end

class User
  attr_accessor :statuses, :name

  def initialize(name = "default")
    @name = name
    @statuses = []
  end

  def get_statuses
    response = EndUser.access_token.get("http://api.twitter.com/1.1/statuses/user_timeline.json?screen_name=#{name}").body
    user_timeline = JSON.parse(response)
    user_timeline.each do |tweet|
      @statuses << Status.new(self, tweet["text"])
    end
    @statuses
  end
end

class EndUser < User
  # "consumer" in OAuth terminology means "client" in our discussion.

  def initialize(name)
    super(name)
    @friends = []
    get_friends
  end

  def self.login(name)
    @@access_token = EndUser.get_token("#{name}.txt")
    @@current_user = EndUser.new(name)
  end

  def self.access_token
    @@access_token
  end

  def self.request_token
    request_token = CONSUMER.get_request_token
    authorize_url = request_token.authorize_url
    puts "Go to this URL: #{authorize_url}"
    Launchy.open(authorize_url)

    puts "Login, and type your verification code in"
    oauth_verifier = gets.chomp
    access_token = request_token.get_access_token(
        :oauth_verifier => oauth_verifier)
  end

  def self.get_token(token_file)
    if File.exist?(token_file)
      File.open(token_file) { |f| YAML.load(f) }
    else
      access_token = EndUser.request_token
      File.open(token_file, "w") { |f| YAML.dump(access_token, f) }

      access_token
    end
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
    status.post_status
    @statuses << status
  end

  def user_timeline
    @@access_token.get("http://api.twitter.com/1.1/statuses/user_timeline.json").body
  end

  def dm(target_user, message)
    uri = Addressable::URI.new(
       :scheme => "https",
       :host => "api.twitter.com",
       :path => "/1.1/direct_messages/new.json",
       :query_values => { :text => message,
                          :screen_name => target_user }
    )
    dm = @@access_token.post(uri.to_s).body
  end

  def get_friends ##rename?
    response =  @@access_token.get("https://api.twitter.com/1.1/friends/list.json").body
    friends_list = JSON.parse(response)
    friends_list["users"].each do |friend|
      @friends << User.new(friend["screen_name"])
      @friends.last.get_statuses
    end
  end

  def show_friends
    puts "Your Tweet Friends"
    @friends.each_with_index { |friend, i| puts "#{i+1} | #{friend.name}" }
  end

  def pick_friend_to_view
    show_friends
    puts "Pick a friend to view their tweets"
    @friends[gets.chomp.to_i-1]
  end

  def show_friend_statuses(friend)
    friend.statuses.each { |status| puts status.tweet }
  end
end

def main
  puts "what shall we call you?"
  name = gets.chomp
  current_user = EndUser.login(name)
  action = nil

  while action != 0
    puts "\n\n\n\n"
    puts "Welcome to TwitterClient 1000.0, #{current_user.name}"
    puts "-----------------------------------------------------"
    puts
    puts "select an action: 1 - Tweet || 2 - View your Timeline || 3 - DM"
    puts "|| 4 - View other user's Timeline || 5 - View Users you are Following || 0 - Exit"
    action = gets.chomp.to_i

    case action
    when 1
      current_user.tweet(current_user.get_tweet)
    when 2
      puts current_user.timeline
    when 3
      current_user.dm(current_user.pick_friend_to_view.name, current_user.get_tweet)
    when 4
      current_user.show_friend_statuses(current_user.pick_friend_to_view)
    when 5
      current_user.show_friends
    else
      puts "thanks for coming"
    end
  end
end

main

