unless Rails.env.production?
  AboutPage.configure do |config|
    config.app           = { :name => DIL.name, :version => DIL::VERSION }
    config.environment   = AboutPage::Environment.new({
      'Ruby' => /^(RUBY|GEM_|rvm)/    # This defines a "Ruby" subsection containing
                                      # environment variables whose names match the RegExp
    })
    config.request       = AboutPage::RequestEnvironment.new({
      'HTTP Server' => /^(SERVER_|POW_)/  # This defines an "HTTP Server" subsection containing
                                          # request variables whose names match the RegExp
    })
    config.dependencies  = AboutPage::Dependencies.new
    config.fedora        = AboutPage::Fedora.new(ActiveFedora::Base.connection_for_pid(0))  # Rubydora::Repository instance
    config.solr          = AboutPage::Solr.new(ActiveFedora.solr.conn, :numDocs => 1)   # RSolr instance
  end
end