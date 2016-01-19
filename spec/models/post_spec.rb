require 'rails_helper'

describe Post, type: :model do

  before  do 
    Post.destroy_all
  end

  describe 'feed_with_cache' do

    let(:poster) { FactoryGirl.create(:user_with_posts) }

    let(:followed_poster) { FactoryGirl.create(:user_with_posts) }

    it 'show for the user his stuff if no other followers' do
      db_post = poster.posts.last
      json_post = Post.feed_with_cache(poster, 0).first
      post = JSON.parse(json_post)
      expect(db_post.id).to  eq(post['id'].to_i)
    end

    it 'show others stuff too when he follows people' do
      poster.follow!(followed_poster)
      db_post = followed_poster.posts.last
      json_post = Post.feed_with_cache(poster, 0).first
      post = JSON.parse(json_post)
      expect(db_post.id).to  eq(post['id'].to_i)
    end

    it 'gets the next page' do
      db_post = poster.posts.order(id: :desc).offset(10).first
      json_post = Post.feed_with_cache(poster, 10, db_post.id+1).first
      post = JSON.parse(json_post)
      expect(db_post.id).to  eq(post['id'].to_i)
    end

  end

end
