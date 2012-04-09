FactoryGirl.define do
  factory :archivist, :class=>User do |u|
    email 'archivist1@example.com'
    password 'archivist1'
  end
  factory :user, :aliases => [:owner] do |u|
    sequence :email do |n|
      "person#{n}@example.com"
    end
    password 'password'
  end

  factory :user_group, :class=>Group do |g|
    name 'Factory Group'
    owner 
  end

  factory :collection, :class=>DILCollection do |g|
  end
end

