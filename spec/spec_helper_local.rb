# frozen_string_literal: true

RSpec.configure do |c|
  c.before :each do
    # support checking private types and classes:
    # Fake assert_private function from stdlib to not fail within this test
    # [weasel 202402]
    Puppet::Parser::Functions.newfunction(:assert_private, type: :rvalue) { |args| }
  end
end
