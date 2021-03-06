require "bibliothecary/version"

Dir[File.expand_path('../bibliothecary/parsers/*.rb', __FILE__)].each do |file|
  require file
end

module Bibliothecary
  def self.analyse(path)
    cmd = `find #{path} -type f | grep -vE "#{ignored_files}"`
    file_list = cmd.split("\n")
    package_managers.map{|pm| pm.analyse(path, file_list) }.flatten.compact
  end

  def self.package_managers
    Bibliothecary::Parsers.constants.map{|c| Bibliothecary::Parsers.const_get(c) }
  end

  def self.ignored_files
    ['.git'].join('|')
  end
end
