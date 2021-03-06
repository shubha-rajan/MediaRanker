class ApplicationController < ActionController::Base
  before_action :set_user

  private

  def set_user
    @current_user = User.find_by(id: session[:user_id])
  end
end
