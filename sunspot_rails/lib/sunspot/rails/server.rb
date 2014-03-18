module Sunspot
  module Rails
    class Server < Sunspot::Solr::Server
      # ActiveSupport log levels are integers; this array maps them to the
      # appropriate java.util.logging.Level constant
      LOG_LEVELS = %w(FINE INFO WARNING SEVERE SEVERE INFO)

      def start
        bootstrap
        super
      end

      def master_start
        master_bootstrap
        super
      end

      def run
        bootstrap
        super
      end

      def master_run
        master_bootstrap
        super
      end

      #
      # Bootstrap a new solr_home by creating all required
      # directories. 
      #
      # ==== Returns
      #
      # Boolean:: success
      #
      def bootstrap
        unless @bootstrapped
          install_solr_home
          @bootstrapped = true
        end
      end

      def master_bootstrap
        unless @master_bootstrapped
          install_master_solr_home
          @master_bootstrapped = true
        end
      end

      #
      # Directory to store custom libraries for solr
      #
      def lib_path
        File.join( solr_home, 'lib' )
      end

      # 
      # Directory in which to store PID files
      #
      def pid_dir
        configuration.pid_dir || File.join(::Rails.root, 'tmp', 'pids')
      end

      # 
      # Name of the PID file
      #
      def pid_file
        "sunspot-solr-#{::Rails.env}.pid"
      end

      def master_pid_file
        "sunspot-master-solr-#{::Rails.env}.pid"
      end

      def master_replication_url
        configuration.master_replication_url
      end
      #
      # Directory to store lucene index data files
      #
      # ==== Returns
      #
      # String:: data_path
      #
      def solr_data_dir
        configuration.data_path
      end

      def master_solr_data_dir
        File.join(master_solr_home, 'data', ::Rails.env)
      end

      #
      # Directory to use for Solr home.
      #
      def solr_home
        File.join(configuration.solr_home)
      end

      def master_solr_home
        File.join(configuration.master_solr_home)
      end


      #
      # Solr start jar
      #
      def solr_jar
        configuration.solr_jar || super
      end

      # 
      # Address on which to run Solr
      #
      def bind_address
        configuration.bind_address
      end

      # 
      # Port on which to run Solr
      #
      def port
        configuration.port
      end

      def master_port
        configuration.master_port
      end

      #
      # Severity level for logging. This is based on the severity level for the
      # Rails logger.
      #
      def log_level
        LOG_LEVELS[::Rails.logger.level]
      end

      # 
      # Log file for Solr. File is in the rails log/ directory.
      #
      def log_file
        File.join(::Rails.root, 'log', "sunspot-solr-#{::Rails.env}.log")
      end

      def master_log_file
        File.join(::Rails.root, 'log', "sunspot-master-solr-#{::Rails.env}.log")
      end

      # 
      # Minimum Java heap size for Solr
      #
      def min_memory
        configuration.min_memory
      end

      # 
      # Maximum Java heap size for Solr
      #
      def max_memory
        configuration.max_memory
      end

      private

      #
      # access to the Sunspot::Rails::Configuration, defined in
      # sunspot.yml. Use Sunspot::Rails.configuration if you want
      # to access the configuration directly.
      #
      # ==== returns
      #
      # Sunspot::Rails::Configuration:: configuration
      #
      def configuration
        Sunspot::Rails.configuration
      end

      # 
      # Directory to store solr config files
      #
      # ==== Returns
      #
      # String:: config_path
      #
      def config_path
        File.join(solr_home, 'conf')
      end

      #
      # Copy default solr configuration files from sunspot
      # gem to the new solr_home/config directory
      #
      # ==== Returns
      #
      # Boolean:: success
      #
      def install_solr_home
        unless File.exists?(solr_home)
          Sunspot::Installer.execute(
            solr_home,
            :force => true,
            :verbose => true,
            :client => configuration.has_master?
          )
        end
      end

      def install_master_solr_home
        unless File.exists?(master_solr_home)
          Sunspot::Installer.execute(
            master_solr_home,
            :force => true,
            :verbose => true,
            :master => true
          )
        end
      end

      #
      # Create new solr_home, config, log and pid directories
      #
      # ==== Returns
      #
      # Boolean:: success
      #
      def create_solr_directories
        [master_solr_data_dir, solr_data_dir, pid_dir].each do |path|
          FileUtils.mkdir_p( path )
        end
      end
    end
  end
end
