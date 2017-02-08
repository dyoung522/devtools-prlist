class Github
  attr_accessor :issues
end

FactoryGirl.define do
  factory :github do
    issues { build_list(:issue, 2) }
  end
end
