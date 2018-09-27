require 'test_helper'

class ImportsControllerTest < ActionDispatch::IntegrationTest
  test 'get_new' do
    get '/imports/new'
    assert_response :success
  end
end
