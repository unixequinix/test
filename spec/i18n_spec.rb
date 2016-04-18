# frozen_string_literal: true
require "i18n/tasks"

RSpec.describe "I18n" do
  let(:i18n) { I18n::Tasks::BaseTask.new }
  let(:missing_keys) { i18n.missing_keys }
  let(:unused_keys) { i18n.unused_keys }

  it "does not have missing keys" do
    str = "Missing #{missing_keys.leaves.count} i18n keys, run `i18n-tasks missing' to show them"
    expect(missing_keys).to be_empty, str
  end

  it "does not have unused keys" do
    str = "#{unused_keys.leaves.count} unused i18n keys, run `i18n-tasks unused' to show them"
    expect(unused_keys).to be_empty, str
  end
end
