FactoryGirl.define do
  factory :archivist, :parent=>:user do |u|
    uid 'archivist1'
    password 'archivist1'
  end
  factory :staff, :parent=>:user do |u|
    uid 'staff1'
    password 'staff1'
    affiliations { ["staff"] }
  end
  factory :student, :parent=>:user do |u|
    uid 'student1'
    password 'student1'
    affiliations { ["student"] }
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

