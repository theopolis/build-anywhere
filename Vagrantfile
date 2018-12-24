targets = {
  "debian8" => {
    "box" => "bento/debian-8"
  },
  "debian9" => {
    "box" => "bento/debian-9"
  },
  "centos7" => {
    "box" => "elastic/centos-7-x86_64"
  },
  "centos6" => {
    "box" => "bento/centos-6.7"
  },
  "ubuntu14" => {
    "box" => "ubuntu/trusty64"
  },
  "ubuntu16" => {
    "box" => "bento/ubuntu-16.04"
  },
  "ubuntu18" => {
    "box" => "ubuntu/bionic64"
  }
}

Vagrant.configure("2") do |config|
  config.vm.provider "virtualbox" do |v|
    if ENV['BUILD_CPUS']
      v.cpus = ENV['BUILD_CPUS'].to_i
    else
      v.cpus = 2
    end
    if ENV['BUILD_MEMORY']
      v.memory = ENV['BUILD_MEMORY'].to_i
    else
      v.memory = 4096
    end
  end

  targets.each do |name, target|
    box = target["box"]
    config.vm.define name do |build|
      build.vm.box = box
    end
  end
end

