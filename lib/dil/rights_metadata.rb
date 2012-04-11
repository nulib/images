module Dil
  module RightsMetadata
    def read_groups
      rightsMetadata.groups.map {|k, v| k if v == 'read'}.compact
    end

    # Grant read permissions to the groups specified. Revokes read permission for all other groups.
    # @param[Array] groups a list of groups
    # @example
    #  r.read_groups= ['one', 'two', 'three']
    #  r.read_groups 
    #  => ['one', 'two', 'three']
    #
    def read_groups=(groups)
      set_read_groups(groups, read_groups)
    end

    # Grant read permissions to the groups specified. Revokes read permission for
    # any of the eligible_groups that are not in groups.
    # This may be used when different users are responsible for setting different
    # groups.  Supply the groups the current user is responsible for as the 
    # 'eligible_groups'
    # @param[Array] groups a list of groups
    # @param[Array] eligible_groups the groups that are eligible to have their read permssion revoked. 
    # @example
    #  r.read_groups = ['one', 'two', 'three']
    #  r.read_groups 
    #  => ['one', 'two', 'three']
    #  r.set_read_groups(['one'], ['three'])
    #  r.read_groups
    #  => ['one', 'two']  ## 'two' was not eligible to be removed
    #
    def set_read_groups(groups, eligible_groups)
      g = rightsMetadata.groups.select {|k, v| v == 'edit'}
      (eligible_groups - groups).each do |group_name|
        #Strip permissions from groups not privided
        g[group_name] = 'none'
      end
      groups.each { |name| g[name] = 'read'}
      rightsMetadata.update_permissions("group"=>g)
    end

  end
end
