require 'spec_helper'

describe PolicyAwareAbility do
  before(:all) do
    class PolicyAwareClass
      include CanCan::Ability
      include Hydra::Ability
      include PolicyAwareAbility
    end
    @policy = AdminPolicy.new
    @policy.default_permissions = [
      {:type=>"group", :access=>"read", :name=>"africana-faculty"},
      {:type=>"group", :access=>"edit", :name=>"cool_kids"},
      {:type=>"group", :access=>"edit", :name=>"in_crowd"},
      {:type=>"user", :access=>"read", :name=>"nero"},
      {:type=>"user", :access=>"edit", :name=>"julius_caesar"},
      ]
      
    @policy.save
    @image = Multiresimage.new()
    @image.admin_policy = @policy
    @image.save
  end
  after(:all) { @policy.delete; @image.delete }
  subject { PolicyAwareClass.new( User.new ) }
  
  describe "policy_pid_for" do
    it "should retrieve the pid doc for the current object's governing policy" do
      subject.policy_pid_for(@image.pid).should == @policy.pid
    end
  end

  describe "policy_permissions_doc" do
    it "should retrieve the permissions doc for the current object's policy and store for re-use" do
      subject.should_receive(:get_permissions_solr_response_for_doc_id).with(@policy.pid).once.and_return(["response", "mock solr doc"])
      subject.policy_permissions_doc(@policy.pid).should == "mock solr doc"
      subject.policy_permissions_doc(@policy.pid).should == "mock solr doc"
      subject.policy_permissions_doc(@policy.pid).should == "mock solr doc"
    end
  end
  describe "test_edit_from_policy" do
    it "should test_edit_from_policy"
  end
  describe "test_read_from_policy" do
    it "should test_read_from_policy"
  end
  describe "edit_groups_from_policy" do
    it "should retrieve the list of groups with edit access from the policy" do
      subject.edit_groups_from_policy(@policy.pid).should == ["cool_kids","in_crowd"]
    end
  end
  describe "edit_persons_from_policy" do
    it "should retrieve the list of individuals with edit access from the policy" do
      subject.edit_persons_from_policy(@policy.pid).should == ["julius_caesar"]
    end
  end
  describe "read_groups_from_policy" do
    it "should retrieve the list of groups with read access from the policy" do
      subject.read_groups_from_policy(@policy.pid).should == ["cool_kids", "in_crowd", "africana-faculty"]
    end
  end
  describe "read_persons_from_policy" do
    it "should retrieve the list of individuals with read access from the policy" do
      subject.read_persons_from_policy(@policy.pid).should == ["julius_caesar","nero"]
    end
  end
end