require 'gemnasium/parser'

module Bibliothecary
  module Parsers
    class Rubygems
      NAME_VERSION = '(?! )(.*?)(?: \(([^-]*)(?:-(.*))?\))?'.freeze
      NAME_VERSION_4 = /^ {4}#{NAME_VERSION}$/
      PLATFORM_NAME = 'Rubygems'

      def self.parse(filename, file_contents)
        if filename.match(/^Gemfile$|^gems\.rb$/)
          manifest = Gemnasium::Parser.send(:gemfile, file_contents)
          parse_manifest(manifest)
        elsif filename.match(/[A-Za-z0-9_-]+\.gemspec$/)
          manifest = Gemnasium::Parser.send(:gemspec, file_contents)
          parse_manifest(manifest)
        elsif filename.match(/^Gemfile\.lock$|^gems\.locked$/)
          parse_gemfile_lock(file_contents)
        else
          []
        end
      end

      def self.analyse(folder_path, file_list)
        [
          analyse_gemfile(folder_path, file_list),
          analyse_gemspec(folder_path, file_list),
          analyse_gemfile_lock(folder_path, file_list)
        ].flatten
      end

      def self.analyse_gemfile(folder_path, file_list)
        path = file_list.find{|path| path.gsub(folder_path, '').gsub(/^\//, '').match(/^Gemfile$|^gems\.rb$/) }
        return unless path

        manifest = Gemnasium::Parser.send(:gemfile, File.open(path).read)

        {
          platform: PLATFORM_NAME,
          path: path,
          dependencies: parse_manifest(manifest)
        }
      end

      def self.analyse_gemspec(folder_path, file_list)
        paths = file_list.select{|path| path.gsub(folder_path, '').gsub(/^\//, '').match(/[A-Za-z0-9_-]+\.gemspec$/) }
        return unless paths.any?

        paths.map do |path|
          manifest = Gemnasium::Parser.send(:gemspec, File.open(path).read)

          {
            platform: PLATFORM_NAME,
            path: path,
            dependencies: parse_manifest(manifest)
          }
        end
      end

      def self.analyse_gemfile_lock(folder_path, file_list)
        path = file_list.find{|path| path.gsub(folder_path, '').gsub(/^\//, '').match(/^Gemfile\.lock$|^gems\.locked$/) }
        return unless path

        manifest = File.open(path).read

        {
          platform: PLATFORM_NAME,
          path: path,
          dependencies: parse_gemfile_lock(manifest)
        }
      end

      def self.parse_gemfile_lock(manifest)
        manifest.split("\n").map do |line|
          match = line.match(NAME_VERSION_4)
          next unless match
          name = match[1]
          version = match[2].gsub(/\(|\)/,'')
          {
            name: name,
            requirement: version,
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
