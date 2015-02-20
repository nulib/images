def login(user)
  OmniAuth.config.test_mode = true
  OmniAuth.config.mock_auth[:ldap] = {
    :provider => 'ldap',
    :uid=> "uid=#{user.uid},ou=people,dc=example,dc=com",
    :info => {
      :name => user.uid + ' User',
      :email => user.uid + '@example.com',
      :nickname => user.uid
    },
    :extra => {
      :raw_info => {
        :edupersonaffiliation => user.affiliations
      }
    }
  }

  allow(Hydra::LDAP).to receive(:groups_owned_by_user) { [] }
  visit '/'
  click_link "Login"

  fill_in "Username", with: user.uid
  fill_in "Password", with: user.password
  click_button "Sign in"
  expect(page).to have_content("Successfully authorized")

end
