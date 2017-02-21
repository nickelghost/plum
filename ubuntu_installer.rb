require 'fileutils'
require 'yaml'
require 'net/ftp'

#Setting a variable of home path for later use.
home = File.expand_path('~')

################################################################################
help = <<-eos
Usage:
  plum <command>

Command List:
  help - display this text
  list - list all packages available
  install <package-name> - install a package from the server
  local-install <package-path> - install a local package
  download <package> <path> - downloads a package to path
  remove <package-name> - remove a package
  reload - relink all packages
eos
################################################################################

puts "Where should plum reside? Default is '.plum' in your home directory. \
Please use an absolute path."
plum_dir = gets.chomp
puts "What about your apps? Default is '.apps' in your home directory. \
Please use an absolute path."
apps_dir = gets.chomp


if plum_dir == ""
  plum_dir = home + "/.plum"
end
if apps_dir == ""
  apps_dir = home + "/.apps"
end

FileUtils.mkdir(plum_dir)
FileUtils.mkdir(apps_dir)
FileUtils.mkdir(plum_dir + "/path")
FileUtils.mkdir(plum_dir + "/path_backups")
# just so I don't forget about manpages :D
FileUtils.mkdir(plum_dir + "/man")
FileUtils.mkdir(plum_dir + "/bin")

FileUtils.cp(__dir__ + "/plum.rb", plum_dir + "/plum.rb")
FileUtils.ln_s(plum_dir + "/plum.rb", plum_dir + "/bin/plum")

File.open("#{plum_dir}/help.txt", "w") do |file|
  file.puts help
end

open(home + '/.bashrc', 'a') do |bashrc|
  bashrc.puts "export PATH=$PATH:#{plum_dir + "/bin"}"
  bashrc.puts "export PATH=$PATH:#{plum_dir + "/path"}"
end

config = {
  apps_path: apps_dir,
  arch: RUBY_PLATFORM.split('-')[0],
  repo_address: "163.172.216.10",
  backups: true
}

File.open(plum_dir + "/config.yml", "w") do |file|
  file.puts(config.to_yaml)
end

FileUtils.touch "#{plum_dir}/software.yml"

puts "Installed. Use 'plum' command to use Plum. You might need to restart your terminal."
