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
install_dnsenum_dependencies(){
packages="alien
perl"
   echo "Installing dnsenum dependency packages"
   for PACKAGE in $packages; do
        __apt_get_install_noinput $PACKAGE >> $HOME/ECC-install.log 2>&1
        ERROR=$?
        if [ $ERROR -ne 0 ]; then
            echo "Install Failure: $PACKAGE (Error Code: $ERROR)"
        else
            echo "Installed Package: $PACKAGE"
        fi
    done
}

install_dnsdict6_dependencies(){
packages="libpcap0.8-dev 
libssl-dev"
   echo "Installing dnsdict6 dependency packages"
   for PACKAGE in $packages; do
        __apt_get_install_noinput $PACKAGE >> $HOME/ECC-install.log 2>&1
        ERROR=$?
        if [ $ERROR -ne 0 ]; then
            echo "Install Failure: $PACKAGE (Error Code: $ERROR)"
        else
            echo "Installed Package: $PACKAGE"
        fi
    done
}
install_perl_modules(){
	perl -MCPAN -e "install Getopt::Long"
	perl -MCPAN -e "install IO::File"	
	perl -MCPAN -e "install Net::Wigle"
	perl -MCPAN -e "install Thread::Queue"
	perl -MCPAN -e "install Net::IP"
	perl -MCPAN -e "install Net::DNS"
	perl -MCPAN -e "install Net::Netmask"
	perl -MCPAN -e "install Net::Whois::IP"
	perl -MCPAN -e "install HTML::Parser"
	perl -MCPAN -e "install XML::Writer"
	perl -MCPAN -e "install String::Random"
	perl -MCPAN -e "install WWW::Mechanize"
}
install_dnsdict6(){
	CDDR=$(pwd)
	mkdir /tmp/dnsdict6
	cp thc-ipv6-1.8.tar.gz /tmp/dnsdict6/
	cd /tmp/dnsdict6
	tar xzvf thc-ipv6-1.8.tar.gz
	cd thc-ipv6-1.8/
	make
	make install
	cd $CDDR
}
install_ECC_Tools() {
  # Installing Burp suite from ECCTools Github Repository
  echo "ECC tools: Copying ECC Tools"
	CDIR=$(pwd)
	git clone --recursive https://github.com/LalithaKurma/ECCTools /tmp/ECCTools >> $HOME/ECC-install.log 2>&1
	cd /tmp/ECCTools
	#bash burpsuite_free_linux_v1_7_16.sh >> $HOME/ECC-install.log 2>&1
        #gdebi netdiscover_0.3beta7~pre+svn118-1_amd64.deb
	printf "\n"
	#echo "* Info: Installing NetDiscover Tool..."        
	#dpkg -i netdiscover_0.3beta7~pre+svn118-1_amd64.deb && apt install -f
	#echo "ECC tools: Completed NetDiscover Tool Installation"
	#printf "\n"
	#echo "* Info: Installing Nmap Tool..."        
	#dpkg -i nmap_7.40-2_amd64.deb && apt install -f
        #echo "ECC tools: Completed Nmap Tool Installation"
	#printf "\n"
	#echo "* Info: Installing Zenmap Tool..."        
	#dpkg -i zenmap_7.40-2_all.deb && apt install -f
        #echo "ECC tools: Completed Zenmap Tool Installation"
	#printf "\n"
	#echo "* Info: Installing recon-ng Tool..."
	#install_recon_ng
	#echo "ECC tools: Completed recon-ng Installation"
	#printf "\n"
	#echo "* Info: Installing Snmpcheck Tool..."        
	#dpkg -i snmpcheck_1.8-5_all.deb && apt install -f
        #echo "ECC tools: Completed Snmpcheck Installation"

		
	#install_dnsenum_dependencies
	#echo "ECC tools: Installing Perl Modules"
	#install_perl_modules
	#echo "ECC tools: Installed Perl Modules"
	#printf "\n"
	#echo "* Info: Installing dnsenum Tool..."        
	#dpkg -i dnsenum_1.2.4.2-6_all.deb && apt install -f
        #echo "ECC tools: Completed dnsenum Installation"
	printf "\n"
	echo "* Info: Installing dnsdict6 Tool..."
	install_dnsdict6_dependencies
	install_dnsdict6
	echo "ECC tools: Completed dnsdict6 Installation"
        cd $CDIR
	rm -r -f /tmp/ECCTools
}

complete_message() {
    echo
    echo "Installation Complete!"
}

#Calling to install ECC-Tools    
echo "ECC: Welcome CEH"
install_ECC_Tools
complete_message


