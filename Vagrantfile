Vagrant.configure("2") do |config|

  config.vm.define "db2" do |db|
    db.vm.box = "redhat65"
	db.vm.host_name = "db2.domain.com"
	#db.vm.network "public_network", bridge: 'Intel(R) Centrino(R) Advanced-N 6205', device: 'eth1'
	db.vm.network "public_network", ip: "192.168.1.1"
	db.vm.provider :virtualbox do |vb|
		vb.name = "VM DB2 SERVER 10.5"
		vb.gui = false
		vb.memory = 4096
		vb.cpus = 2
	end
	db.vm.provision :shell, :path => "install_db2.sh"

  end

  config.vm.define "bpm" do |bpm|
    bpm.vm.box = "redhat65"
	bpm.vm.host_name = "bpm.domain.com"
	#bpm.vm.network "public_network", bridge: 'Intel(R) Centrino(R) Advanced-N 6205', device: 'eth1'
	bpm.vm.network "public_network", ip: "192.168.1.2"
	bpm.vm.network "forwarded_port", guest: 28000, host: 8080, host_ip: "127.0.0.1"
	bpm.vm.network "forwarded_port", guest: 28001, host: 8081, host_ip: "127.0.0.1"
	bpm.vm.network "forwarded_port", guest: 28041, host: 8082, host_ip: "127.0.0.1"
	bpm.vm.network "forwarded_port", guest: 28042, host: 8083, host_ip: "127.0.0.1"
	bpm.vm.provider :virtualbox do |vb|
		vb.name = "VM IBM BPM 8.5.5"
		vb.gui = false
		vb.memory = 6144
		vb.cpus = 2
	end
	bpm.vm.provision :shell, :path => "install_bpm855.sh"
  end
  
  config.vm.define "ihs" do |ihs|
    ihs.vm.box = "redhat65"
	ihs.vm.host_name = "ihs.domain.com"
	#ihs.vm.network "public_network", bridge: 'Intel(R) Centrino(R) Advanced-N 6205', device: 'eth1'
	ihs.vm.network "public_network", ip: "192.168.1.3"
	ihs.vm.provider :virtualbox do |vb|
		vb.name = "VM IBM IHS 8.5.5"
		vb.gui = false
		vb.memory = 2048
		vb.cpus = 2
	end
	ihs.vm.provision :shell, :path => "install_ihs855.sh"
  end
  
end