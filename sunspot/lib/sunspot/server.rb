require 'escape'
require 'set'
require 'tempfile'

module Sunspot
  class Server #:nodoc:
    # Raised if #stop is called but the server is not running
    ServerError = Class.new(RuntimeError)
    AlreadyRunningError = Class.new(ServerError)
    NotRunningError = Class.new(ServerError)

    # Name of the sunspot executable (shell script)
    SOLR_START_JAR = File.expand_path(
      File.join(File.dirname(__FILE__), '..', '..', 'solr', 'start.jar')
    )

    LOG_LEVELS = Set['SEVERE', 'WARNING', 'INFO', 'CONFIG', 'FINE', 'FINER', 'FINEST']

    attr_accessor :min_memory, :max_memory, :port, :solr_data_dir, :solr_home, :log_file, :master_port, :master_solr_data_dir, :master_solr_home, :master_replication_url
    attr_writer :pid_dir, :pid_file, :log_level, :solr_data_dir, :solr_home, :solr_jar

    #
    # Start the sunspot-solr server. Bootstrap solr_home first,
    # if neccessary.
    #
    # ==== Returns
    #
    # Boolean:: success
    #
    def start
      if File.exist?(pid_path)
        existing_pid = IO.read(pid_path).to_i
        begin
          Process.kill(0, existing_pid)
          raise(AlreadyRunningError, "Server is already running with PID #{existing_pid}")
        rescue Errno::ESRCH
          STDERR.puts("Removing stale PID file at #{pid_path}")
          FileUtils.rm(pid_path)
        end
      end
      fork do
        pid = fork do
          Process.setsid
          STDIN.reopen('/dev/null')
          STDOUT.reopen('/dev/null', 'a')
          STDERR.reopen(STDOUT)
          run
        end
        FileUtils.mkdir_p(pid_dir)
        File.open(pid_path, 'w') do |file|
          file << pid
        end
      end
    end

    def master_start
      if File.exist?(master_pid_path)
        existing_pid = IO.read(master_pid_path).to_i
        begin
          Process.kill(0, existing_pid)
          raise(AlreadyRunningError, "Server is already running with PID #{existing_pid}")
        rescue Errno::ESRCH
          STDERR.puts("Removing stale PID file at #{master_pid_path}")
          FileUtils.rm(master_pid_path)
        end
      end
      fork do
        pid = fork do
          Process.setsid
          STDIN.reopen('/dev/null')
          STDOUT.reopen('/dev/null', 'a')
          STDERR.reopen(STDOUT)
          master_run
        end
        FileUtils.mkdir_p(pid_dir)
        File.open(master_pid_path, 'w') do |file|
          file << pid
        end
      end

    end

    # 
    # Run the sunspot-solr server in the foreground. Boostrap
    # solr_home first, if neccessary.
    #
    # ==== Returns
    #
    # Boolean:: success
    #
    def run
      command = ['java']
      command << "-Xms#{min_memory}" if min_memory
      command << "-Xmx#{max_memory}" if max_memory
      command << "-Djetty.port=#{port}" if port
      command << "-Dsolr.data.dir=#{solr_data_dir}" if solr_data_dir
      command << "-Dsolr.solr.home=#{solr_home}" if solr_home
      command << "-javaagent:#{Sunspot::Rails.configuration.newrelic}" if Sunspot::Rails.configuration.newrelic
      command << "-Dnewrelic.environment=#{::Rails.env}" if Sunspot::Rails.configuration.newrelic
      command << "-Dreplication.url=#{master_replication_url}" if master_replication_url
      command << "-Djava.util.logging.config.file=#{logging_config_path}" if logging_config_path
      command << '-jar' << File.basename(solr_jar)
      FileUtils.cd(File.dirname(solr_jar)) do
        exec(Escape.shell_command(command))
      end
    end

    def master_run
      command = ['java']
      command << "-Xms#{min_memory}" if min_memory
      command << "-Xmx#{max_memory}" if max_memory
      command << "-Djetty.port=#{master_port}" if master_port
      command << "-Dsolr.data.dir=#{master_solr_data_dir}" if master_solr_data_dir
      command << "-Dsolr.solr.home=#{master_solr_home}" if master_solr_home
      command << "-javaagent:#{Sunspot::Rails.configuration.newrelic}" if Sunspot::Rails.configuration.newrelic
      command << "-Dnewrelic.environment=#{::Rails.env}" if Sunspot::Rails.configuration.newrelic
      command << "-Djava.util.logging.config.file=#{logging_config_path}" if logging_config_path
      command << '-jar' << File.basename(solr_jar)
      FileUtils.cd(File.dirname(solr_jar)) do
        exec(Escape.shell_command(command))
      end
    end

    #
    # Stop the sunspot-solr server.
    #
    # ==== Returns
    #
    # Boolean:: success
    #
    def stop
      if File.exist?(pid_path)
        pid = IO.read(pid_path).to_i
        begin
          Process.kill('TERM', pid)
        rescue Errno::ESRCH
          raise NotRunningError, "Process with PID #{pid} is no longer running"
        ensure
          FileUtils.rm(pid_path)
        end
      else
        raise NotRunningError, "No PID file at #{pid_path}"
      end
    end

    def master_stop
      if File.exist?(master_pid_path)
        pid = IO.read(master_pid_path).to_i
        begin
          Process.kill('TERM', pid)
        rescue Errno::ESRCH
          raise NotRunningError, "Process with PID #{pid} is no longer running"
        ensure
          FileUtils.rm(master_pid_path)
        end
      else
        raise NotRunningError, "No PID file at #{master_pid_path}"
      end
    end

    def log_level=(level)
      unless LOG_LEVELS.include?(level.to_s.upcase)
        raise(ArgumentError, "#{level} is not a valid log level: Use one of #{LOG_LEVELS.to_a.join(',')}")
      end
      @log_level = level.to_s.upcase
    end

    def log_level
      @log_level || 'WARNING'
    end

    def pid_path
      File.join(pid_dir, pid_file)
    end

    def master_pid_path
      File.join(pid_dir, master_pid_file)
    end

    def pid_dir
      File.expand_path(@pid_dir || FileUtils.pwd)
    end

    def solr_data_dir
      File.expand_path(@solr_data_dir || Dir.tmpdir)
    end

    def solr_home
      File.expand_path(@solr_home || File.join(File.dirname(solr_jar), 'solr'))
    end

    def solr_jar
      @solr_jar || SOLR_START_JAR
    end

    private

    def logging_config_path
      return @logging_config_path if defined?(@logging_config_path)
      @logging_config_path =
        if log_file
          logging_config = Tempfile.new('logging.properties')
          logging_config.puts("handlers = java.util.logging.FileHandler")
          logging_config.puts("java.util.logging.FileHandler.level = #{log_level.to_s.upcase}")
          logging_config.puts("java.util.logging.FileHandler.pattern = #{log_file}")
          logging_config.puts("java.util.logging.FileHandler.formatter = java.util.logging.SimpleFormatter")
          logging_config.flush
          logging_config.close
          logging_config.path
        end
    end
  end
end
