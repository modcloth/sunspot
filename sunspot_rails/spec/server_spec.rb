require File.expand_path('spec_helper', File.dirname(__FILE__))

describe Sunspot::Rails::Server do
  before :each do
    @server = Sunspot::Rails::Server.new
    @config = Sunspot::Rails::Configuration.new
    @solr_home = File.join(@config.solr_home)
    @master_solr_home = File.join(@config.master_solr_home)
  end

  context "client" do

    it "sets the correct Solr home" do
      @server.solr_home.should == @solr_home
    end

    it "sets the correct Solr library path" do
      @server.lib_path.should == File.join(@solr_home, 'lib')
    end

    it "sets the correct Solr PID path" do
      @server.pid_path.should == File.join(@server.pid_dir, 'sunspot-solr-test.pid')
    end

    it "sets the correct Solr PID path" do
      @server.pid_path.should == File.join(Rails.root, 'tmp', 'pids', 'sunspot-solr-test.pid')
    end

    it "sets the correct Solr data dir" do
      @server.solr_data_dir.should == File.join(@solr_home, 'data', 'test')
    end

    it "sets the correct port" do
      @server.port.should == 8983
    end

    it "sets the correct log level" do
      @server.log_level.should == "FINE"
    end

    it "sets the correct log file" do
      @server.log_file.should == File.join(Rails.root, 'log', 'sunspot-solr-test.log')
    end

    it "sets the correct master replication url" do
      @server.master_replication_url.should == "http://localhost:9981/solr/replication"
    end
  end

  context "master" do
    it "sets the correct Solr home" do
      @server.master_solr_home.should == @master_solr_home
    end

    it "sets the correct Solr PID path" do
      @server.master_pid_path.should == File.join(Rails.root, 'tmp', 'pids', 'sunspot-master-solr-test.pid')
    end

    it "sets the correct Solr data dir" do
      @server.master_solr_data_dir.should == File.join(@master_solr_home, 'data', 'test')
    end

    it "sets the correct port" do
      @server.master_port.should == 9981
    end

    it "sets the correct log file" do
      @server.master_log_file.should == File.join(Rails.root, 'log', 'sunspot-master-solr-test.log')
    end

  end
end
