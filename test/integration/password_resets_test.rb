require 'test_helper'

class PasswordResetsTest < ActionDispatch::IntegrationTest
  
  def setup
    ActionMailer::Base.deliveries.clear
    @user = users(:michael)
  end

  test "password resets" do
    get new_password_reset_path
    assert_template 'password_resets/new'
    # 無効なメールアドレス
    post password_resets_path, params: { password_reset: { email: ""}}
    assert_not flash.empty?
    assert_template 'password_resets/new'
    # 有効なメールアドレス
    post password_resets_path, params: { password_reset: {email: @user.email}}
    assert_not_equal @user.reset_digest, @user.reload.reset_digest
    assert_equal 1, ActionMailer::Base.deliveries.size
    assert_not flash.empty?
    assert_redirected_to root_url
    # パスワード再設定フォームのテスト
    user = assigns(:user)
    # メールアドレスが無効
    get edit_password_reset_path(user.reset_token, email: "")
    assert_redirected_to root_url
    # 無効なユーザー
    user.toggle!(:activated)
    get edit_password_reset_path(user.reset_token, email: user.email)
    assert_redirected_to root_url
    user.toggle!(:activated)
    # メールアドレス有効、トークン無効
    get edit_password_reset_path('wrong token', email: user.email)
    assert_redirected_to root_url
    # メールアドレスとトークンが有効
    get edit_password_reset_path(user.reset_token, email: user.email)
    assert_template 'password_resets/edit'
    assert_select "input[name=email][type=hidden][value=?]", user.email
    # 無効なパスワードとパスワード確認
    patch password_reset_path(user.reset_token),
      params: { email: user.email,
                  user: { password: "foobaz",
                     password_confirmation: "barquux" }}
    assert_select 'div#error_explanation'
    # パスワードが空
    patch password_reset_path(user.reset_token),
      params: { email: user.email,
                  user: {password: "",
                    password_confirmation: "" }}
    assert_select 'div#error_explanation'
    # 有効なパスワードとパスワード確認
    patch password_reset_path(user.reset_token),
      params: { email: user.email,
                  user: {password: "foobaz",
                    password_confirmation: "foobaz" }}
    assert is_logged_in?
    assert_not flash.empty?
    assert_redirected_to user
  end

  test "expired token" do
    get new_password_reset_path
    post password_resets_path,
      params: { password_reset: { email: @user.email }}
    user = assigns(:user)
    user.update_attribute(:reset_sent_at, 3.hours.ago)
    patch password_reset_path(user.reset_token),
      params: { email: @user.email,
                  user: { password: "foobar",
                          password_confirmation: "foobar" }}
    assert_response :redirect
    follow_redirect!
    assert_match /expired/i, response.body
  end

  test "clear reset digest after resetting password" do
    get new_password_reset_path
    post password_resets_path, 
      params: { password_reset: { email: @user.email }}
    assert_redirected_to root_url
    user = assigns(:user)
    reset_token = user.reset_token
    get edit_password_reset_path(reset_token, email: user.email)
    assert_template 'password_resets/edit'
    assert_select "input[name=email][type=hidden][value=?]", user.email
    patch password_reset_path(reset_token), 
      params: { email: user.email, 
                user: { password: "newpassword",
                        password_confirmation: "newpassword" }}
    assert is_logged_in?
    assert_not flash.empty?
    assert_redirected_to user
    get edit_password_reset_path(reset_token, email: user.email)
    assert_response :redirect
    assert_redirected_to root_url
    follow_redirect!
    assert_nil user.reload.reset_digest
  end
end
