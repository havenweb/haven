require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test "should not save a user without basic_auth credentials" do
    assert_raises ActiveRecord::RecordInvalid do
      User.create!(
        email: "alexander@hamilton.com",
        name: "Alexander Hamilton",
        password: "alexes password",
        admin: 0)
    end
  end

  test "should save a user with all data" do
    assert User.create!(
      email: "alexander@hamilton.com",
      password: "alexes password",
      admin: 0,
      basic_auth_username: "abcd",
      basic_auth_password: "efgh",
      image_password: "1234")
  end
end
