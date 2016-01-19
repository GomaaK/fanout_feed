class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  has_many :posts, dependent: :destroy

  after_create :add_self_to_users_followed

  #
  # get a list of ids of the users followed by this user
  #
  def followed
    $redis.lrange("users:#{id}:followed", 0, -1)
  end

  #
  # get a list of ids of the users following this user
  #
  def followers
    $redis.lrange("users:#{id}:followers", 0, -1)
  end

  #
  # this will get the data of the followed users
  # and cache them 
  #
  def followed_data
    data = $redis.get("users:#{id}:cache")
    return data unless data.blank?
    users = User.find(followed).to_json(only: [:name, :avatar])
    $redis.set("users:#{id}:cache", users) unless users.blank?
    users
  end

  #
  # add a user to the list of followed users
  # this invalidates the whole cache of this user
  #
  def follow!(user)
    $redis.lpush("users:#{id}:followed", user.id)
    $redis.lpush("users:#{user.id}:followers", id)
    remove_all_from_cache
  end

  #
  # removes the user from the list of followed users
  # this invalidates the whole cache of this user
  #
  def unfollow!(user)
    $redis.lpush("users:#{id}:followed", user.id)
    $redis.lpush("users:#{user.id}:followers", id)
    remove_all_from_cache
  end




  def remove_all_from_cache
    $redis.del("feed:#{id}")
    $redis.del("users:#{id}:cache")
  end

  

  private

  #
  # you see your own activity don't you
  #
  def add_self_to_users_followed
    follow!(self)
  end
end
