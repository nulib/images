module Dil
  module LDAP
    class NoUsersError < StandardError; end
    def self.connection
      @ldap_conn ||= Net::LDAP.new(ldap_config) 
    end

    def self.ldap_config
      return @ldap_config if @ldap_config
      @ldap_config = {:auth=>{:method=>:simple}}
      yml = YAML.load_file(File.join(Rails.root, 'config', 'ldap.yml'))[Rails.env].with_indifferent_access
      @ldap_config[:host] = yml[:host]
      @ldap_config[:port] = yml[:port]
      @ldap_config[:auth][:username] = yml[:username]
      @ldap_config[:auth][:password] = yml[:password]
      @ldap_config
    end

    def self.base
      "ou=Groups,#{treebase}"
    end

    def self.treebase
      "dc=example,dc=com"
    end

    def self.dn(code)
      dn = "cn=#{code},#{Dil::LDAP.base}"
    end

    def self.create_group(code, users)
      raise NoUsersError, "Unable to persist a group without users" unless users.present?
      attributes = {
        :cn => code,
        :objectclass => "groupofnames",
        :member=>users.map {|u| "uid=#{u}"}
      }
      connection.add(:dn=>dn(code), :attributes=>attributes)
    end

    def self.delete_group(code)
      Dil::LDAP.connection.delete(:dn=>dn(code))
    end

    # same as
    # ldapsearch -h ec2-107-20-53-121.compute-1.amazonaws.com -p 389 -x -b dc=example,dc=com -D "cn=admin,dc=example,dc=com" -W "(&(objectClass=groupofnames)(member=uid=vanessa))" cn
    def self.groups_for_user(uid)
      result = Dil::LDAP.connection.search(:base=>treebase, :filter=> Net::LDAP::Filter.construct("(&(objectClass=groupofnames)(member=uid=#{uid}))"), :attributes=>['cn'])
      result.map{|r| r[:cn].first}
    end
    def self.users_for_group(group_code)
      result = Dil::LDAP.connection.search(:base=>treebase, :filter=> Net::LDAP::Filter.construct("(&(objectClass=groupofnames)(cn=#{group_code}))"), :attributes=>['cn'])
      result.map{|r| r[:cn].first}
    end

  end
end
