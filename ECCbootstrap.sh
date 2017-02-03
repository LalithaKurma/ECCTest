__apt_get_install_noinput() {
    apt-get install -y -o DPkg::Options::=--force-confold $@; return $?
}
install_recon_ng(){
   packages="python-pip"
   CDDR=$(pwd)
   cd /tmp/ECCTools/reconng
   __apt_get_install_noinput $PACKAGE >> $HOME/ECC-install.log 2>&1
        ERROR=$?
        if [ $ERROR -ne 0 ]; then
            echo "Install Failure: $package (Error Code: $ERROR)"
        else
            echo "Installed Package: $PACKAGE"
        fi
    done
    pip install -r REQUIREMENTS 
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
	dpkg -i netdiscover_0.3beta7~pre+svn118-1_amd64.deb && apt install -f
	echo "ECC tools: Completed NetDiscover Tool Installation"
	echo "* Info: Installing Nmap Tool..."        
	dpkg -i nmap_7.40-2_amd64.deb && apt install -f
        echo "ECC tools: Completed Nmap Tool Installation"
	echo "* Info: Installing recon-ng Tool..."
	install_recon_ng
	echo "ECC tools: Completed recon-ng Installation"
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


