FactoryGirl.define do
  factory :archivist, :parent=>:user do |u|
    uid 'archivist1'
    password 'archivist1'
  end
  factory :user, :aliases => [:owner] do |u|
    sequence :uid do |n|
      "person#{n}"
    end
    email { "#{uid}@example.com" }
    password { uid } 
  end

  factory :user_group, :class=>Group do |g|
    name 'Factory Group'
    owner 
  end

  factory :collection, :class=>DILCollection do |g|
    sequence :title do |n|
      "Title #{n}"
    end
  end
end

