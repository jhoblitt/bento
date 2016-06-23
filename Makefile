BIN_DIR=./packer

$(BIN_DIR):
	mkdir $@
	cd $@; wget -nc https://releases.hashicorp.com/packer/0.10.1/packer_0.10.1_linux_amd64.zip
	cd $@; unzip packer_0.10.1_linux_amd64.zip
