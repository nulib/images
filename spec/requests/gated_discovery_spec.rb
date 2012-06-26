require 'spec_helper'

describe "When I am searching for content" do
  context "Given an image with no custom access set" do
    before { @pid = "inu:dil-default-access-image" }
    context "Then someone with NU id" do
      before { login FactoryGirl.find_or_create(:nu_id_holder) }
      before { visit catalog_index_path(:q=>@pid) }
      it "should not be able to discover the image" do
        page.should_not have_selector("a[href='#{multiresimage_path(@pid)}']")
      end
    end
    context "Then the Creator" do
      before { login FactoryGirl.find_or_create(:joe_creator) }
      before { visit catalog_index_path(:q=>"Tibetan_astronomical_Thangka_4") }
      it "should be able to discover the image" do
        page.should have_selector("a[href='#{multiresimage_path(@pid)}']")
      end 
    end
    context "Then a Repository Admin" do
      before { login FactoryGirl.find_or_create(:alice_admin) }
      before { visit multiresimage_path(@pid) }
      it "should be able to discover the image" do
        pending "Repo admin permissions"
        page.should have_selector("a[href='#{multiresimage_path(@pid)}']")
      end
    end
  end

  context "Given an image which NU has read access to" do
    before { @pid = "inu:dil-nu-read-access-image" }
    context "The someone with NU id" do
      before { login FactoryGirl.find_or_create(:nu_id_holder) }
      before { visit catalog_index_path(:q=>@pid) }
      it "should be able to discover the image" do
        page.should have_selector("a[href='#{multiresimage_path(@pid)}']", :text=> "The Fabric of the Human Body (1992). Muscles an...")
      end
    end
  end

  context "Given an image with collaborator" do
    before { @pid = "inu:dil-nu-read-access-image" }
    context "Then a collaborator with edit access" do
      before { login FactoryGirl.find_or_create(:calvin_collaborator) }
      before { visit catalog_index_path(:q=>@pid) }
      it "should be able to discover the image" do
        page.should have_selector("a[href='#{multiresimage_path(@pid)}']", :text=> "The Fabric of the Human Body (1992). Muscles an...")
      end 
    end
  end
  
  context "Given an image where dept can read & NU can discover" do
    before { @pid = "inu:dil-dept-access-image" }
    context "Then someone with NU id" do
      before { login FactoryGirl.find_or_create(:nu_id_holder) }
      before { visit catalog_index_path(:q=>@pid) }
      it "should be able to discover the image" do
        page.should have_selector("a[href='#{multiresimage_path(@pid)}']")
      end 
    end
    context "Then someone whose department has read access" do
      before { login FactoryGirl.find_or_create(:martia_morocco) }
      before { visit catalog_index_path(:q=>@pid) }
      it "should be able to discover the image" do
        page.should have_selector("a[href='#{multiresimage_path(@pid)}']")
      end
    end
  end


  context "Given a policy grants edit access to a group I belong to" do
    before do
      # @image = Multiresimage.new()
      # @image.policy=@policy
      # @image.save
    end
    it "Then I should be able to discover the image" do
      pending "Policy permissions"
      subject.can?(:discover, @image).should be_true
    end
  end
  context "Given a policy grants read access to a group I belong to" do
    before do
      # @image = Multiresimage.new()
      # @image.policy=@policy
      # @image.save
    end
    it "Then I should be able to discover the image" do
      pending "Policy permissions"
      subject.can?(:discover, @image).should be_true
    end
  end
end

