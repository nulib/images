FactoryGirl.define do
  
  # Users
  
  factory :archivist, :parent=>:user do |u|
    uid 'archivist1'
    password 'archivist1'
  end
  factory :nu_id_holder, :parent=>:user do |u|
    uid 'nu_id_holder'
    password 'nu_id_holder'
  end
  factory :staff, :parent=>:user do |u|
    uid 'staff1'
    password 'staff1'
    affiliations ["staff"]
  end
  factory :student, :parent=>:user do |u|
    uid 'student1'
    password 'student1'
    affiliations ["student"]
  end
  factory :joe_creator, :parent=>:user do |u|
    uid 'joe_creator'
    password 'joe_creator'
    affiliations ["faculty"]
  end
  factory :martia_morocco, :parent=>:user do |u|
    uid 'martia_morocco'
    password 'martia_morocco'
    affiliations ["faculty"]
    group_codes ["africana-faculty"]
  end
  factory :ira_instructor, :parent=>:user do |u|
    uid 'ira_instructor'
    password 'ira_instructor'
    affiliations ["faculty"]
    group_codes ["africana-faculty"]
  end
  factory :calvin_collaborator, :parent=>:user do |u|
    uid 'calvin_collaborator'
    password 'calvin_collaborator'
    affiliations ["student"]
  end
  factory :sara_student, :parent=>:user do |u|
    uid 'sara_student'
    password 'sara_student'
    affiliations  ["student"]
    group_codes ["africana-104-students"]
  end
  factory :louis_librarian, :parent=>:user do |u|
    uid 'louis_librarian'
    password 'louis_librarian'
    affiliations ["library-staff"]
    group_codes ["repository-admin"]
  end
  factory :carol_curator, :parent=>:user do |u|
    uid 'carol_curator'
    password 'carol_curator'
    affiliations ["library-staff"]
    group_codes ["repository-admin"]
  end
  factory :alice_admin, :parent=>:user do |u|
    uid 'alice_admin'
    password 'alice_admin'
    group_codes ["repository-admin"]
  end

  
  
  factory :user, :aliases => [:owner] do |u|
    sequence :uid do |n|
      "person#{n}"
    end
    email { "#{uid}@example.com" }
    password { uid }
  end

  # Groups
  
  factory :user_group, :class=>Group do |g|
    name 'Factory Group'
    owner 
  end

  # Collections
  
  factory :collection, :class=>DILCollection do |g|
    sequence :title do |n|
      "Title #{n}"
    end
  end
end

