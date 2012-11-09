module DIL
	module PidMinter
	  
	  # This generates a UUID per the RFC 4122 version 4 specification
      def mint_pid(prefix)
        pid = "inu:#{prefix}-" << SecureRandom.uuid
      end
      
    end
end
