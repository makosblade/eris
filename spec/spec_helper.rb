require 'json'
require 'securerandom'
require 'fileutils'
require 'c3d'
require 'epm'
require File.join(File.dirname(__FILE__), '..', 'eris')

ERIS_REPO = 'https://github.com/project-douglas/eris.git'

RSpec.configure do |config|
  config.mock_with :rspec
  config.before(:suite) do
    get_set_up
  end
  config.after(:all) do
  end
end

def get_set_up
  C3D::SetupC3D.new

  C3D::ConnectTorrent.supervise_as :puller, {
      username: ENV['TORRENT_USER'],
      password: ENV['TORRENT_PASS'],
      url:      ENV['TORRENT_RPC'] }
  $puller           = Celluloid::Actor[:puller]

  C3D::ConnectEth.supervise_as :eth, :cpp
  $eth              = Celluloid::Actor[:eth]

  unless check_for_doug
    print "\nThere is No DOUG. Please Fix That."
    exit 0
  end
end

def check_for_doug
  log_file = File.join(ENV['HOME'], '.epm', 'deployed-log.csv')
  begin
    log  = File.read log_file
    doug = log.split("\n").map{|l| l.split(',')}.select{|l| l[0] == ("Doug" || "DOUG" || "doug")}[-1][-1]
  rescue
    EPM::Deploy.new(ERIS_REPO).deploy_package
    log  = File.read log_file
    doug = log.split("\n").map{|l| l.split(',')}.select{|l| l[0] == ("Doug" || "DOUG" || "doug")}[-1][-1]
  end
  doug_check = $eth.get_storage_at doug, '0x10'
  if doug_check != '0x'
    return true
  else
    return false
  end
end