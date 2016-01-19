class ApplicationController < ActionController::Base

  before_action :set_user

  def set_user
    @user = User.find params[:user_id]
  end
end
