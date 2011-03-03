require File.expand_path('spec_helper', File.dirname(__FILE__))

describe Sunspot::Rails::Configuration, "default values without a sunspot.yml" do
  before(:each) do
    File.stub(:exist?).and_return(false) # simulate sunspot.yml not existing
    @config = Sunspot::Rails::Configuration.new
  end

  it "should handle the 'hostname' property when not set" do
    @config.hostname.should == 'localhost'
  end

  it "should handle the 'path' property when not set" do
    @config.path.should == '/solr/default'
  end

  describe "port" do
    it "should default to port 8981 in test" do
      ::Rails.stub(:env => 'test')
      @config = Sunspot::Rails::Configuration.new
      @config.port.should == 8981
    end
    it "should default to port 8982 in development" do
      ::Rails.stub(:env => 'development')
      @config = Sunspot::Rails::Configuration.new
      @config.port.should == 8982
    end
    it "should default to 8983 in production" do
      ::Rails.stub(:env => 'production')
      @config = Sunspot::Rails::Configuration.new
      @config.port.should == 8983
    end
    it "should generally default to 8983" do
      ::Rails.stub(:env => 'staging')
      @config = Sunspot::Rails::Configuration.new
      @config.port.should == 8983
    end
  end

  describe "master_port" do
    it "should default to master_port 9981 in test" do
      ::Rails.stub!(:env => 'test')
      @config = Sunspot::Rails::Configuration.new
      @config.master_port.should == 9981
    end
    it "should default to port 9982 in development" do
      ::Rails.stub!(:env => 'development')
      @config = Sunspot::Rails::Configuration.new
      @config.master_port.should == 9982
    end
    it "should default to 9983 in production" do
      ::Rails.stub!(:env => 'production')
      @config = Sunspot::Rails::Configuration.new
      @config.master_port.should == 9983
    end
    it "should generally default to 9983" do
      ::Rails.stub!(:env => 'staging')
      @config = Sunspot::Rails::Configuration.new
      @config.master_port.should == 9983
    end
  end

  it "should set the read timeout to nil when not set" do
    @config.read_timeout == nil
  end

  it "should set the open timeout to nil when not set" do
    @config.open_timeout == nil
  end

  it "should set 'log_level' property using Rails log level when not set" do
    ::Rails.logger.stub(:level){ 3 }
    @config.log_level.should == 'SEVERE'
  end
  
  it "should handle the 'log_file' property" do
    @config.log_file.should =~ /log\/solr_test.log/
  end

  it "should handle the 'solr_home' property when not set" do
    Rails.should_receive(:root).at_least(1).and_return('/some/path')
    @config.solr_home.should == '/some/path/solr'
  end

  it "should handle the 'master_solr_home' property when not set" do
    Rails.should_receive(:root).at_least(1).and_return('/some/master_path')
    @config.master_solr_home.should == '/some/master_path/master_solr'
  end

  it "should handle the 'data_path' property when not set" do
    Rails.should_receive(:root).at_least(1).and_return('/some/path')
    @config.data_path.should == '/some/path/solr/data/test'
  end

  it "should handle the 'master_data_path' property when not set" do
    Rails.should_receive(:root).at_least(1).and_return('/some/master_path')
    @config.master_data_path.should == '/some/master_path/master_solr/data/test'
  end

  it "should handle the 'pid_dir' property when not set" do
    Rails.should_receive(:root).at_least(1).and_return('/some/path')
    @config.pid_dir.should == '/some/path/solr/pids/test'
  end

  it "should handle the 'master_pid_path' property when not set" do
    Rails.should_receive(:root).at_least(1).and_return('/some/master_path')
    @config.master_pid_path.should == '/some/master_path/master_solr/pids/test'
  end

  it "should handle the 'auto_commit_after_request' propery when not set" do
    @config.auto_commit_after_request?.should == true
  end

  it "should handle the 'auto_commit_after_delete_request' propery when not set" do
    @config.auto_commit_after_delete_request?.should == false
  end

  it "should handle the 'bind_address' property when not set" do
    @config.bind_address.should be_nil
  end

  it "should handle the 'disabled' property when not set" do
    @config.disabled?.should be_false
  end
end

describe Sunspot::Rails::Configuration, "user provided sunspot.yml" do
  before(:each) do
    ::Rails.stub(:env => 'config_test')
    @config = Sunspot::Rails::Configuration.new
  end

  context "client" do
    it "should handle the 'hostname' property when set" do
      @config.hostname.should == 'some.host'
    end

    it "should handle the 'port' property when set" do
      @config.port.should == 1234
    end

    it "should handle the 'path' property when set" do
      @config.path.should == '/solr/idx'
    end

    it "should handle the 'pid_dir' property when set" do
      @config.pid_dir.should == '/my_superior_path/pids'
    end
    
    it "should handle the 'auto_commit_after_delete_request' propery when set" do
      @config.auto_commit_after_delete_request?.should == true
    end

    it "should handle the 'bind_address' property when set" do
      @config.bind_address.should == "127.0.0.1"
    end

    it "should handle the 'read_timeout' property when set" do
      @config.read_timeout.should == 2
    end

    it "should handle the 'open_timeout' property when set" do
      @config.open_timeout.should == 0.5
    end
  end
  context "master" do
    it "should handle the 'hostname' property when set" do
      @config.master_hostname.should == 'some.master_host'
    end

    it "should handle the 'port' property when set" do
      @config.master_port.should == 4321
    end

    it "should handle the 'path' property when set" do
      @config.master_path.should == '/master_solr/idx'
    end

    it "should handle the 'log_level' propery when set" do
      @config.master_log_level.should == 'INFO'
    end

    it "should handle the 'solr_home' propery when set" do
      @config.master_solr_home.should == '/my_master_path'
    end

    it "should handle the 'data_path' property when set" do
      @config.master_data_path.should == '/my_master_path/data'
    end

    it "should handle the 'master_pid_dir' property when set" do
      @config.master_pid_dir.should == '/my_master_path/pids'
    end    
  end
  
end

describe Sunspot::Rails::Configuration, "with disabled: true in sunspot.yml" do
  before(:each) do
    ::Rails.stub(:env => 'config_disabled_test')
    @config = Sunspot::Rails::Configuration.new
  end

  it "should handle the 'disabled' property when set" do
    @config.disabled?.should be_true
  end
end

describe Sunspot::Rails::Configuration, "with ENV['SOLR_URL'] overriding sunspot.yml" do
  before(:all) do
    ENV['SOLR_URL'] = 'http://environment.host:5432/solr/env'
  end

  before(:each) do
    ::Rails.stub(:env => 'config_test')
    @config = Sunspot::Rails::Configuration.new
  end

  after(:all) do
    ENV.delete('SOLR_URL')
  end

  it "should handle the 'hostname' property when set" do
    @config.hostname.should == 'environment.host'
  end

  it "should handle the 'port' property when set" do
    @config.port.should == 5432
  end

  it "should handle the 'path' property when set" do
    @config.path.should == '/solr/env'
  end
end

describe Sunspot::Rails::Configuration, "with ENV['WEBSOLR_URL'] overriding sunspot.yml" do
  before(:all) do
    ENV['WEBSOLR_URL'] = 'http://index.websolr.test/solr/a1b2c3d4e5f'
  end

  before(:each) do
    ::Rails.stub(:env => 'config_test')
    @config = Sunspot::Rails::Configuration.new
  end

  after(:all) do
    ENV.delete('WEBSOLR_URL')
  end

  it "should handle the 'hostname' property when set" do
    @config.hostname.should == 'index.websolr.test'
  end

  it "should handle the 'port' property when set" do
    @config.port.should == 80
  end

  it "should handle the 'path' property when set" do
    @config.path.should == '/solr/a1b2c3d4e5f'
  end
end

