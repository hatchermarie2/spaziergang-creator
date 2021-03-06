require 'rails_helper'

RSpec.feature 'Sign up', type: :feature do
  scenario 'user creates new account' do
    visit root_path
    click_link I18n.t('signup.label')
    fill_in 'Username', with: 'test2'
    fill_in 'Email', with: 'test@test.de'
    fill_in 'Password', with: '1234567890abcde'
    fill_in 'Password confirmation', with: '1234567890abcde'
    click_button 'Sign up'

    expect(page).to have_content("Ahoi, test@test.de!")
  end
end
