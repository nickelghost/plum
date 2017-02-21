#!/usr/bin/ruby
require 'fileutils'
require 'yaml'
require 'net/ftp'

# software is the configuration base of each program, whilst config is
# for sole plum
@config = YAML.load(File.open("#{__dir__}/config.yml"))
@software = YAML.load(File.open("#{__dir__}/software.yml"))

# if software.yml is empty, @software will return false, but it needs to be a
# hash, so it sets it as an empty one
unless @software
  @software = {}
end

# method that updates software.yml
def write_software
  File.open("#{__dir__}/software.yml", 'w') do |file|
    file.puts(@software.to_yaml)
  end
end

# that wonderful thing "installs" the software; links path and such, and should
# support manpages in the future
def reload
  exec_path_list = {}

  # the loop creates a hash in the pattern of {folder_name: {
  #   exec1_name: exec1_path,
  #   exec2_name: exec2_path},
  # ...}
  @software.each do |soft_name, properties|
    exec_path_list[soft_name] = {}

    # core executable
    exec_path_list[soft_name][soft_name] = properties[:exec]

    # additional executables, like for example npm to node
    if properties[:add_exec]
      properties[:add_exec].each do |add_soft_name, add_soft_path|
        exec_path_list[soft_name][add_soft_name] = add_soft_path
      end
    end
  end

  # clean current shortcuts in the path folder
  path_list = Dir.glob("#{__dir__}/path/*")
  path_list.each do |file|
    File.delete file
  end

  # generate a name for the backup
  b_name = Time.new.to_i.to_s + Random.rand(1000).to_s

  # just creates a folder for the backup
  if @config[:backups] == true
    backup_folder = "#{__dir__}/path_backups/#{b_name}"
    FileUtils.mkdir(backup_folder)
  end

  # the whole thing is supposed to create links to the path folder, with
  # optional backup copies
  exec_path_list.each do |folder_name, hash|
    hash.each do |soft_name, exec_path|
      app_path = "#{@config[:apps_path]}/#{folder_name}/#{exec_path}"
      next unless File.exist?(app_path)
      path_path = "#{__dir__}/path/#{soft_name}"
      FileUtils.ln_s(app_path, path_path)

      # makes a backup for the future
      if @config[:backups] == true
        backup_path = "#{__dir__}/path_backups/#{b_name}/#{soft_name}"
        FileUtils.ln_s(app_path, backup_path)
      end
    end
  end
end

# installs any archive
def install_local(file_path)
  file_path = File.expand_path(file_path)
  folder_name = file_path.split('/')[-1].split('.')[0]
  puts 'Unpacking...'
  system("tar -xzf #{file_path} -C /tmp")

  puts 'Reading \'plum.yml\'...'
  config = YAML.load(File.open("/tmp/#{folder_name}/plum.yml"))

  puts 'Updating software config...'
  @software = @software.merge(config)

  puts 'Writing new software config...'
  write_software

  puts 'Installing files...'
  FileUtils.mv("/tmp/#{folder_name}", @config[:apps_path])

  puts 'Linking...'
  reload
end

# downloads any archive to any place
def download(name, path)
  path = File.expand_path(path)
  filename = "#{name}.tar.gz"
  puts 'Connecting...'
  Net::FTP.open(@config[:repo_address]) do |server|
    server.login
    puts "Downloading '#{filename}'..."
    server.getbinaryfile("repo/#{@config[:arch]}/#{filename}", "#{path}/#{filename}")
  end
end

# combines 'download' and 'install_local', also cleans up after them
def install(name)
  download(name, '/tmp')
  archive_path = "/tmp/#{name}.tar.gz"
  install_local(archive_path)
  puts 'Cleaning up...'
  FileUtils.rm(archive_path)
end

# uninstalling - removes app's folder and removes the app from software.yml
def remove(name)
  puts 'Removing files...'
  FileUtils.rm_r("#{@config[:apps_path]}/#{name}")
  puts 'Updating software config...'
  @software.reject! { |k| k == name.to_sym }
  puts 'Writing new software config...'
  write_software
  puts 'Linking...'
  reload
end

def list_package_names
  Net::FTP.open(@config[:repo_address]) do |server|
    server.login
    software = server.list("repo/#{@config[:arch]}/")
    software.each do |line|
      puts line.split(' ')[8].split('.')[0]
    end
  end
end

# argument handling
if ARGV.empty?
  puts 'Please specify an argument. Use "help" for help.'
else

  case ARGV[0].downcase
  when 'help'
    puts File.read("#{__dir__}/help.txt")
  when 'install'
    install(ARGV[1])
  when 'install-local'
    install_local(ARGV[1])
  when 'remove'
    remove(ARGV[1])
  when 'reload'
    reload
  when 'download'
    download(ARGV[1], ARGV[2])
  when 'list'
    list_package_names
  else
    puts 'Unknown argument. Use "help" for help.'
  end

end
