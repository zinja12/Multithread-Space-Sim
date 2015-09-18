#!/usr/bin/ruby
require 'fileutils'
to_copy = %w(.submit space.rb)
to_copy << ".submitUser" if File.exist? ".submitUser"
FileUtils.mkdir_p '.submitdir'
FileUtils.cp to_copy, '.submitdir/'
Dir.chdir(".submitdir") do
  system "java -jar ../submit.jar"
  FileUtils.cp ".submitUser", "../" unless File.exist? "../.submitUser"
end
