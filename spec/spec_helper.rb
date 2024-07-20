# frozen_string_literal: true

require "rspec"
require_relative "../lib/summary_bot"

RSpec.configure do |config|
  config.color = true
  config.formatter = :documentation
end
