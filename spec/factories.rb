FactoryGirl.define do
  factory :archivist, :class=>User do |u|
    email 'archivist1@example.com'
    password 'archivist1'
  end
  factory :user do |u|
    sequence :email do |n|
      "person#{n}@example.com"
    end
    password 'password'
  end
end

