
  def log_in_with(u) # u is a hash with fields email: and pass:
    visit root_url
    fill_in "user_email", with: u[:email]
    fill_in "user_password", with: u[:pass]
    click_on "Log in"
  end

  # when a user is already logged in
  def make_post(content)
    click_on "Home"
    click_on "New Post Button"
    fill_in "post_content", with: content
    click_on "Save Post"
    assert_text content
  end
