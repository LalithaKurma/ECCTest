__apt_get_install_noinput() {
    apt-get install -y -o DPkg::Options::=--force-confold $@; return $?
}
#install_recon_ng(){
#   packages="python-pip
#git
#python
#python-pip
#python-dnspython
#python-mechanize
#python-slowaes
#python-xlsxwriter
#python-jsonrpclib
#python-lxml"
#   CDDR=$(pwd)
#   cd /tmp/ECCTools/reconng
#   packages="$packages"
#   echo "Installing Python packages"
#   for PACKAGE in $packages; do
#        __apt_get_install_noinput $PACKAGE >> $HOME/ECC-install.log 2>&1
#        ERROR=$?
#        if [ $ERROR -ne 0 ]; then
#            echo "Install Failure: $PACKAGE (Error Code: $ERROR)"
#        else
#            echo "Installed Package: $PACKAGE"
#        fi
#    done
#    #pip install -r REQUIREMENTS 
#    cp -r /tmp/ECCTools/reconng /home/cast/
#    cd $CDDR
#}
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
libssl1.0.0
libssl-dev
openssl"
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
install_fierce_perl_modules(){
	perl -MCPAN -e "install Net::CIDR"
	perl -MCPAN -e "install Net::Whois::ARIN"
	perl -MCPAN -e "install Object::InsideOut"
	perl -MCPAN -e "install Template"
	perl -MCPAN -e "install Test::Class"
	perl -MCPAN -e "install Test::MockObject"
	perl -MCPAN -e "install Net::DNS"
	perl -MCPAN -e "install Net::hostent"
	perl -MCPAN -e "install WWW::Mechanize"

}
install_fierce(){
	CDDR=$(pwd)
	mkdir /tmp/fierce
	cp -r fierce2 /tmp/fierce/
	cd /tmp/fierce/fierce2
	perl Makefile.PL
	make
	make test
	make install
	mkdir -p /pentest/enumeration/fierce/
	ln -s /usr/local/bin/fierce /pentest/enumeration/fierce/fierce
	cp -R tt ~/.fierce2/
	cd $CDDR
}
install_metasploit_dependencies(){
packages="openjdk-6-jdk
build-essential
bundler
libreadline-dev
libssl-dev
libpq5
libpq-dev
libreadline5
libsqlite3-dev
libpcap-dev
git-core
gnupg2
autoconf
postgresql
postgresql-contrib
pgadmin3
curl
zlib1g-dev
libxml2-dev
libxslt1-dev
vncviewer
libyaml-dev
curl
zlib1g-dev
nmap"
#oracle-java8-installer"
	echo "Adding the Oracle Java Package Source Repository"
	add-apt-repository -y ppa:webupd8team/java  >> $HOME/ECC-install.log 2>&1 || return 1
	echo "Updating Repository Package List ..."
    	apt-get update >> $HOME/ECC-install.log 2>&1 || return 1

   echo "Installing Metasploit dependency packages"
   for PACKAGE in $packages; do
        __apt_get_install_noinput $PACKAGE >> $HOME/ECC-install.log 2>&1
        ERROR=$?
        if [ $ERROR -ne 0 ]; then
            echo "Install Failure: $PACKAGE (Error Code: $ERROR)"
        else
            echo "Installed Package: $PACKAGE"
        fi
    done
	#apt-get -y install oracle-java8-installer
	
	echo "Updating Repository Package List ..."
    	apt-get update >> $HOME/ECC-install.log 2>&1 || return 1
}
install_metasploit(){
	CDDR=$(pwd)
	cd /home/cast/
	echo "Installing and Configuring RVM"

	#gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
	#\curl -sSL https://get.rvm.io | bash -s stable --ruby
	curl -sSL https://rvm.io/mpapis.asc | gpg2 --import -
	curl -L https://get.rvm.io | bash -s stable
	source /usr/local/rvm/scripts/rvm
	echo "source /usr/local/rvm/scripts/rvm" >> ~/.bashrc
	source ~/.bashrc
	RUBYVERSION=$(wget https://raw.githubusercontent.com/rapid7/metasploit-framework/master/.ruby-version -q -O - )
	rvm install $RUBYVERSION	
	rvm use $RUBYVERSION --default
	rvm install ruby-2.4.0
	gem install bundler
	echo "Configuring Postgresql..."
	#sudo -s
	#su postgres
	#apt-get isntall postgresql postgresql-contrib
	#sudo -u postgres psql postgres
	#psql
	#CREATE USER msf WITH PASSWORD 'msf' CREATEDB;
	#createdb -O msf msf
	#\q
	#exit
	#createuser msf -P -S -R -D
	#createdb -O msf msf
	
	sudo -u postgres psql -c "CREATE USER msf WITH PASSWORD 'msf' CREATEDB;"
	sudo -u postgres createdb -O msf msf
	echo "Downloading and Installing Metasploit Framework..."
	git clone https://github.com/rapid7/metasploit-framework.git
	cd metasploit-framework/
	#rvm --install '.ruby-version'
	rvm --default use ruby-${RUByVERSION}@metasploit-framework
	rvm gemset create metasploit-framework
	gem install bundler
	bundle install
	gem install rubygems-bundler
	gem regenerate_binstubs #| bundle install
	gem install pg -v 0.19.0
	gem install multi_test -v 0.1.2	
	bundle install
	gem update bundler
	bundle install
	echo "Configuring Metasploit Framework.."
	cp ~/metasploit-framework/config/database.yml.example ~/metasploit-framework/config/database.yml
        cp /tmp/ECCTools/database.yml ~/metasploit-framework/config/database.yml
	sudo sh -c "echo export MSF_DATABASE_CONFIG=/home/cast/metasploit-framework/config/database.yml >> /etc/profile"
	source /etc/profile
	cd $CDDR
}
install_slowloris_dependencies(){
packages="git
perl 
libwww-mechanize-shell-perl"
	echo "Updating Repository Package List ..."
    	apt-get update >> $HOME/ECC-install.log 2>&1 || return 1

   echo "Installing slowloris dependency packages"
   for PACKAGE in $packages; do
        __apt_get_install_noinput $PACKAGE >> $HOME/ECC-install.log 2>&1
        ERROR=$?
        if [ $ERROR -ne 0 ]; then
            echo "Install Failure: $PACKAGE (Error Code: $ERROR)"
        else
            echo "Installed Package: $PACKAGE"
        fi
    done
	perl -MCPAN -e "install WWW::Mechanize"
}
install_slowloris(){
	CDDR=$(pwd)
	cd /home/cast/
	git clone https://github.com/llaera/slowloris.pl
	cd $CDDR
}
install_ECC_Tools() {
  
  echo "ECC tools: Copying ECC Tools"

	CDIR=$(pwd)
	git clone --recursive https://github.com/LalithaKurma/ECCTools /tmp/ECCTools >> $HOME/ECC-install.log 2>&1
	cd /tmp/ECCTools

	#CDIR=$(pwd)
	#git clone --recursive https://github.com/LalithaKurma/ECCTools /tmp/ECCTools >> $HOME/ECC-install.log 2>&1
	#cd /tmp/ECCTools
	#echo "Updating Ubuntu Repositories.."	
	#apt-get update >> $HOME/ECC-install.log 2>&1 || return 1
	#bash burpsuite_free_linux_v1_7_16.sh >> $HOME/ECC-install.log 2>&1
        #gdebi netdiscover_0.3beta7~pre+svn118-1_amd64.deb
	#printf "\n"
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
	#printf "\n"
	#echo "* Info: Installing dnsdict6 Tool..."
	#install_dnsdict6_dependencies
	#install_dnsdict6
	#echo "ECC tools: Completed dnsdict6 Installation"
	#echo "ECC tools: Installing fierce Perl Modules"
	#install_fierce_perl_modules
	#echo "ECC tools: Installed fierce Perl Modules"
	#printf "\n"
	#echo "* Info: Installing fierce Tool..."        
	#install_fierce
        #echo "ECC tools: Completed fierce Installation"
	install_metasploit_dependencies
	install_metasploit
	echo "ECC tools: Completed Metasploit Framework Installation"
#	printf "\n"
	#install_slowloris_dependencies
	#echo "* Info: Installing slowloris.pl Tool..."
	#install_slowloris
	#echo "ECC tools: Completed slowloris.pl Installation"
#	printf "\n"

 #       cd $CDIR
#	rm -r -f /tmp/ECCTools

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


