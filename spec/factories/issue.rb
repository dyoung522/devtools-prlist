class Issue
  attr_accessor :created_at, :labels, :number, :repository_url, :title

  def pull_request?
    true
  end
end

class Label
  attr_accessor :color, :default, :id, :name, :url
end

FactoryGirl.define do
  factory :label do
    id 243750542
    url "https://api.github.com/repos/foobar/baz-bat/labels/Please%20Review"
    name "Please Review"
    color "fef2c0"
    default false
  end

  factory :issue do
    created_at "2016-11-10 17:59:57.000000000 Z"
    labels { build_list(:label, 5) }
    number 512
    repository_url "https://api.github.com/repos/foobar/baz-bat"
    title "NO-JIRA os confirmation dialog wrapper"
  end
end
