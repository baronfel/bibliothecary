require 'gemnasium/parser'
require 'yaml'

module Bibliothecary
  module Parsers
    class CocoaPods
      NAME_VERSION = '(?! )(.*?)(?: \(([^-]*)(?:-(.*))?\))?'.freeze
      NAME_VERSION_4 = /^ {4}#{NAME_VERSION}$/

      def self.analyse(folder_path, file_list)
        [
          analyse_podfile(folder_path, file_list),
          analyse_podspec(folder_path, file_list),
          analyse_podfile_lock(folder_path, file_list)
        ]
      end

      def self.analyse_podfile(folder_path, file_list)
        path = file_list.find{|path| path.gsub(folder_path, '').gsub(/^\//, '').match(/^Podfile$/) }
        return unless path

        manifest = Gemnasium::Parser.send(:podfile, File.open(path).read)

        {
          platform: 'CocoaPods',
          path: path,
          dependencies: parse_manifest(manifest)
        }
      end

      def self.analyse_podspec(folder_path, file_list)
        path = file_list.find{|path| path.gsub(folder_path, '').gsub(/^\//, '').match(/^[A-Za-z0-9_-]+\.podspec$/) }
        return unless path

        manifest = Gemnasium::Parser.send(:podspec, File.open(path).read)

        {
          platform: 'CocoaPods',
          path: path,
          dependencies: parse_manifest(manifest)
        }
      end

      def self.analyse_podfile_lock(folder_path, file_list)
        path = file_list.find{|path| path.gsub(folder_path, '').gsub(/^\//, '').match(/^Podfile\.lock$/) }
        return unless path

        manifest = YAML.load File.open(path).read

        {
          platform: 'CocoaPods',
          path: path,
          dependencies: parse_podfile_lock(manifest)
        }
      end

      def self.parse_podfile_lock(manifest)
        manifest['PODS'].map do |row|
          pod = row.is_a?(String) ? row : row.keys.first
          match = pod.match(/(.+?)\s\((.+?)\)/i)
          {
            name: match[1].split('/').first,
            requirement: match[2],
            type: 'runtime'
          }
        end.compact
      end

      def self.parse_manifest(manifest)
        manifest.dependencies.inject([]) do |deps, dep|
          deps.push({
            name: dep.name,
            requirement: dep.requirement.to_s,
            type: dep.type
          })
        end.uniq
      end
    end
  end
end