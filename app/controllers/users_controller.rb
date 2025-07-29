require 'wordlist'

class UsersController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:create_demo_user]
  before_action :authenticate_user!, except: [:create_demo_user]
  before_action :verify_admin, except: [:create_demo_user]

  def index
    @users = User.order(email: :asc)
  end
  
  def new
    @user = User.new
  end

  def create_demo_user
    @email = params[:email]
    if @email.nil? || @email.empty?
      @email = Wordlist.word_and_num(3) + "@example.com"
    end
    @password = Devise.friendly_token.first(20)
    admin = 2 # Publisher
    unless @email.nil? or (@email=="")
      @user = User.create!(
        email: @email,
        name: "",
        admin: admin,
        password: @password,
        basic_auth_username: Devise.friendly_token.first(10),
        basic_auth_password: Devise.friendly_token.first(10),
        image_password: Devise.friendly_token.first(20)
      )
      login_link = LoginLink.generate(@user)
      @token = login_link.token
      render :show_demo_user
    else
      render :demo_no_email
    end
  end

  def create
    @password = Devise.friendly_token.first(20)
    admin = 0 # Subscriber
    admin = 1 if params[:user][:role] == "admin"
    admin = 2 if params[:user][:role] == "publisher"
    email = params[:user][:email]
    name = params[:user][:name]
    @user = User.create!( 
      email: email,
      name: name,
      admin: admin,
      password: @password,
      basic_auth_username: Devise.friendly_token.first(10),
      basic_auth_password: Devise.friendly_token.first(10),
      image_password: Devise.friendly_token.first(20)
    )
    @verb = "created"
    login_link = LoginLink.generate(@user)
    @token = login_link.token
    render :show
  end

  def resetpassword
    @password = Devise.friendly_token.first(20)
    @user = User.find(params[:id])
    auth_user = Devise.friendly_token.first(10)
    auth_pass = Devise.friendly_token.first(10)
    image_pass = Devise.friendly_token.first(20)
    @user.update(password: @password, basic_auth_username: auth_user, basic_auth_password: auth_pass, image_password: image_pass)
    @verb = "updated"
    @user.login_links.each {|ll| ll.destroy} ## delete old links
    login_link = LoginLink.generate(@user)
    @token = login_link.token
    render :show
  end

  def toggleadmin
    @user = User.find(params[:id])
    @user.admin = (@user.admin + 1) % 3 #toggle between 1 (Admin), 2 (Subscriber)  and 0 (Subscriber)
    @user.save
    redirect_to users_path
  end

  def destroy
    @user = User.find(params[:id])
    @user.destroy
    redirect_to users_path
  end


end
