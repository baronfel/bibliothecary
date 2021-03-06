# packages.config
# Project.json
# Project.lock.json
# *.nuspec

require 'ox'
require 'json'

module Bibliothecary
  module Parsers
    class Nuget
      PLATFORM_NAME = 'nuget'

      def self.parse(filename, file_contents)
        if filename.match(/Project\.json$/)
          json = JSON.parse file_contents
          parse_project_json(json)
        elsif filename.match(/Project\.lock\.json$/)
          json = JSON.parse file_contents
          parse_project_lock_json(json)
        elsif filename.match(/packages\.config$/)
          xml = Ox.parse file_contents
          parse_packages_config(xml)
        elsif filename.match(/^[A-Za-z0-9_-]+\.nuspec$/)
          xml = Ox.parse file_contents
          parse_nuspec(xml)
        else
          []
        end
      end

      def self.analyse(folder_path, file_list)
        [analyse_project_json(folder_path, file_list),
        analyse_project_lock_json(folder_path, file_list),
        analyse_packages_config(folder_path, file_list),
        analyse_nuspec(folder_path, file_list)]
      end

      def self.analyse_project_json(folder_path, file_list)
        path = file_list.find{|path| path.gsub(folder_path, '').gsub(/^\//, '').match(/Project\.json$/) }
        return unless path

        manifest = JSON.parse File.open(path).read

        {
          platform: PLATFORM_NAME,
          path: path,
          dependencies: parse_project_json(manifest)
        }
      end

      def self.analyse_project_lock_json(folder_path, file_list)
        path = file_list.find{|path| path.gsub(folder_path, '').gsub(/^\//, '').match(/Project\.lock\.json$/) }
        return unless path

        manifest = JSON.parse File.open(path).read

        {
          platform: PLATFORM_NAME,
          path: path,
          dependencies: parse_project_lock_json(manifest)
        }
      end

      def self.analyse_packages_config(folder_path, file_list)
        path = file_list.find{|path| path.gsub(folder_path, '').gsub(/^\//, '').match(/packages\.config$/) }
        return unless path

        manifest = Ox.parse File.open(path).read

        {
          platform: PLATFORM_NAME,
          path: path,
          dependencies: parse_packages_config(manifest)
        }
      end

      def self.analyse_nuspec(folder_path, file_list)
        path = file_list.find{|path| path.gsub(folder_path, '').gsub(/^\//, '').match(/^[A-Za-z0-9_-]+\.nuspec$/) }
        return unless path

        manifest = Ox.parse File.open(path).read

        {
          platform: PLATFORM_NAME,
          path: path,
          dependencies: parse_nuspec(manifest)
        }
      end

      def self.parse_project_json(manifest)
        manifest.fetch('dependencies',[]).map do |name, requirement|
          {
            name: name,
            requirement: requirement,
            type: 'runtime'
          }
        end
      end

      def self.parse_project_lock_json(manifest)
        manifest.fetch('libraries',[]).map do |name, requirement|
          dep = name.split('/')
          {
            name: dep[0],
            requirement: dep[1],
            type: 'runtime'
          }
        end
      end

      def self.parse_packages_config(manifest)
        manifest.packages.locate('package').map do |dependency|
          {
            name: dependency.id,
            version: dependency.version,
            type: 'runtime'
          }
        end
      end

      def self.parse_nuspec(manifest)
        manifest.package.metadata.dependencies.locate('dependency').map do |dependency|
          {
            name: dependency.id,
            version: dependency.attributes[:version] || '*',
            type: 'runtime'
          }
        end
      end
    end
  end
end
