__apt_get_install_noinput() {
    apt-get install -y -o DPkg::Options::=--force-confold $@; return $?
}
install_recon_ng(){
   packages="python-pip
git
python-pip
python-dnspython
python-mechanize
python-slowaes
python-xlsxwriter
python-jsonrpclib
python-lxml"
   CDDR=$(pwd)
   cd /tmp/ECCTools/reconng
   packages="$packages"
   echo "Installing Python packages"
   for PACKAGE in $packages; do
        __apt_get_install_noinput $PACKAGE >> $HOME/ECC-install.log 2>&1
        ERROR=$?
        if [ $ERROR -ne 0 ]; then
            echo "Install Failure: $PACKAGE (Error Code: $ERROR)"
        else
            echo "Installed Package: $PACKAGE"
        fi
    done
    #pip install -r REQUIREMENTS 
    cp -r /tmp/ECCTools/reconng /home/cast/
    cd $CDDR
}
install_ECC_Tools() {
  # Installing Burp suite from ECCTools Github Repository
  echo "ECC tools: Installing ECC Tools"
	CDIR=$(pwd)
	git clone --recursive https://github.com/LalithaKurma/ECCTools /tmp/ECCTools >> $HOME/ECC-install.log 2>&1
	cd /tmp/ECCTools
	#bash burpsuite_free_linux_v1_7_16.sh >> $HOME/ECC-install.log 2>&1
        #gdebi netdiscover_0.3beta7~pre+svn118-1_amd64.deb	
	echo "* Info: Installing NetDiscover Tool..."        
	dpkg -i netdiscover_0.3beta7~pre+svn118-1_amd64.deb && apt install -f >> $HOME/ECC-install.log 2>&1 || return 1
	echo "ECC tools: Completed NetDiscover Tool Installation"
	echo "* Info: Installing Nmap Tool..."        
	dpkg -i nmap_7.40-2_amd64.deb && apt install -f >> $HOME/ECC-install.log 2>&1 || return 1
        echo "ECC tools: Completed Nmap Tool Installation"
	echo "* Info: Installing Zenmap Tool..."        
	dpkg -i zenmap_7.40-2_all.deb && apt install -f >> $HOME/ECC-install.log 2>&1 || return 1
        echo "ECC tools: Completed Zenmap Tool Installation"
	echo "* Info: Installing recon-ng Tool..."
	install_recon_ng
	echo "ECC tools: Completed recon-ng Installation"
	echo "* Info: Installing Snmpcheck Tool..."        
	dpkg -i snmpcheck_1.8-5_all.deb && apt install -f >> $HOME/ECC-install.log 2>&1 || return 1
        echo "ECC tools: Completed Snmpcheck Installation"
        cd $CDIR
	rm -r -f /tmp/ECCTools
}

complete_message() {
    echo
    echo "Installation Complete!"
}

#Calling to install ECC-Tools    
echo "ECC: Welcome"
install_ECC_Tools
complete_message


