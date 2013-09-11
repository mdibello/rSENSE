require 'test_helper'

class NewsTest < ActionDispatch::IntegrationTest
  setup do
    Capybara.current_driver = Capybara.javascript_driver
  end

  teardown do
    Capybara.reset_sessions!
  end
  
  test "add a news item" do
    login("nixon", "12345")
    assert find('#title_bar').has_content?('Richard N.')

    click_on "News"
    assert page.has_no_content?("The Quick Brown Fox")
    
    click_on "Add News Item"
    find('.dropdown-toggle').click
    click_on("Edit Title")
    find('#appendInput').set("The Quick Brown Fox")
    all('.menu_save_link').first.click

    find('#hide_news_checkbox').click

    visit '/news'

    assert page.has_content?("The Quick Brown Fox")

    logout

    login("kate", "12345")
    click_on "News" 
    
    assert page.has_no_content?("Add News Item")
    assert page.has_content?("The Quick Brown Fox")
  end

  private

  def login(user, pass)
    visit '/'
    find('#title_bar').click_on('Login')
    fill_in 'Username', with: user
    fill_in 'Password', with: pass
    find('#login_box').click_on('Login')
  end

  def logout
    visit '/'
    find('#title_bar').click_on('Logout')
  end
end
