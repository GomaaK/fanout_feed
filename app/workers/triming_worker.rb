class TrimingWorker
  include Sidekiq::Worker
  
  def perform(*ids)
    ids.each { |id| $redis.ltrim("feed:#{id}", 0, Post::CACHE_LIMIT) }
    
  end
end