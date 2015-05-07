$:.unshift File.expand_path('..', __FILE__)
$:.unshift File.expand_path('../../lib', __FILE__)
require 's3_asset_sync'
require 'rspec'

require_relative './helpers'

RSpec.configure do |c|
  c.include Helpers
  c.mock_with :rspec
end
