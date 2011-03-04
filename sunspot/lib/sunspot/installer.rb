%w(task_helper library_installer schema_builder solrconfig_updater).each do |file|
  require File.join(File.dirname(__FILE__), 'installer', file)
end

module Sunspot
  class Installer
    class <<self
      def execute(solr_home, options = {})
        new(solr_home, options).execute
      end

      private :new
    end

    def initialize(solr_home, options)
      @solr_home, @options = solr_home, options
    end

    def execute
      SchemaBuilder.execute(
        File.join(@solr_home, 'conf', 'schema.xml'),
        @options
      )
      filename = 'solrconfig.xml'
      if @options[:client]
        filename = 'solrconfig_client.xml'
      elsif @options[:master]
        filename = 'solrconfig_master.xml'
      end
      SolrconfigUpdater.execute(
        File.join(@solr_home, 'conf', filename),
        @options
      )
      File.rename(File.join(@solr_home, 'conf', filename), File.join(@solr_home, 'conf', 'solrconfig.xml'))

      LibraryInstaller.execute(File.join(@solr_home, 'lib'), @options)
    end
  end
end
