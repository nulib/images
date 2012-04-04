FactoryGirl.define do
  factory :archivist, :class=>User do |u|
    email 'archivist1@example.com'
    password 'archivist1'
  end
end

