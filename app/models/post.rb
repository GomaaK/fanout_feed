class Post < ActiveRecord::Base
  CACHE_LIMIT = 100
  PER_PAGE = 10

  belongs_to :user

  after_create :push_to_all

  #
  # will check redis if it is there awesome return them
  # if not gets the last 10 posts created
  # and add them to redis for caching
  #  
  # DB performance
  #   Limit  (cost=6.45..6.45 rows=1 width=40)
  # ->  Sort  (cost=6.45..6.45 rows=1 width=40)
  #       Sort Key: id
  #       ->  Seq Scan on posts  (cost=0.00..6.44 rows=1 width=40)
  #             Filter: (user_id = ANY ('{1,2,3}'::integer[]))
  # (5 rows)
  #
  # def self.feed(user, offset, last_id=nil)
  #   results = where(user_id: user.followed).order(id: :desc)
  #   results = results.where("id < #{last_id}") if last_id
  #   results = results.map(&:to_json)
  #   results
  # end
  #
  # def self.feed_with_cache(user, offset, last_id=nil)
  #   cached = get_from_cache(user.id, offset)
  #   return cached if cached
  # 
  #   results = where(user_id: user.followed).order(id: :desc)
  #   results = results.where("id < #{last_id}") if last_id
  #   results = results.map(&:to_json)
  #   cache_and_return_results(user.id, results)
  # end
  #
  #                  real       stime      utime      total
  # with c&failing   41.010000   1.580000  42.590000 ( 46.110835)  done 10000
  # without c        28.660000  0.850000   29.510000 ( 32.662422)  done 10000
  # with c           4.010000   0.170000   4.180000  (  4.182409)  done 10000
  #
  # this means that even if we have a 65% cache miss 
  # we beat the no caching model
  #
  # we can actually try to improve this method by retrieving json from db
  #
  # to handle the space complexity I make expiry for the redis keys
  # if we set a maximum size for redis and set the maxmemory-policy to 
  # volatile-lru
  # redis will remove the records closest to death once it reaches the maximum 
  # size
  #
  def self.feed_with_cache(user, offset, last_id=nil)
    logger.info "checking for cache"
    cached = get_from_cache(user.id, offset)
    logger.debug cached.inspect
    return cached unless cached.blank?
    logger.info "not cached"
    results = where(user_id: user.followed).order(id: :desc)
    results = results.where("id < #{last_id}") if last_id
    results = results.map(&:to_json)
    cache_and_return_results(user.id, results)
  end

  def self.get_from_cache(user_id, offset)
    return nil if (offset + PER_PAGE) >= CACHE_LIMIT
    page_name = "feed:#{user_id}"
    results = $redis.lrange(page_name, offset, PER_PAGE)
    $redis.expire(page_name, 86400) if results
    results
  end

  def self.cache_and_return_results(id, json_results)
    $redis.pipelined{ json_results.each { |result| $redis.rpush("feed:#{id}", result) } }
    return json_results.first(10)
  end


  private

  #
  # this will make sure no one uses this verion cached
  # as it will miss this newly created record
  #
  def push_to_all
    me_in_json = self.to_json
    followers = user.followers
    $redis.pipelined { followers.each { |u_id| $redis.lpush("feed:#{u_id}", me_in_json) }}
  end

end
