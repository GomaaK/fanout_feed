class PostsController < ApplicationController
  skip_before_filter :verify_authenticity_token

  def index
    unless params[:offset_id] && params[:offset]
      hash = {
        posts: Post.feed_with_cache(@user, 0),
        users: @user.followed_data
      }
    else
      hash = {
        posts: Post.feed_with_cache(@user, params[:offset].to_i, params[:offset_id].to_i)
      }
    end
    render json: hash
  end


end