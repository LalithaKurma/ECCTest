#!/bin/bash -
#===============================================================================
# vim: softtabstop=4 shiftwidth=4 expandtab fenc=utf-8 spell spelllang=en cc=81
#===============================================================================


#--- FUNCTION ----------------------------------------------------------------
# NAME: __function_defined
# DESCRIPTION: Checks if a function is defined within this scripts scope
# PARAMETERS: function name
# RETURNS: 0 or 1 as in defined or not defined
#-------------------------------------------------------------------------------
__function_defined() {
    FUNC_NAME=$1
    if [ "$(command -v $FUNC_NAME)x" != "x" ]; then
        echoinfo "Found function $FUNC_NAME"
        return 0
    fi
    
    echodebug "$FUNC_NAME not found...."
    return 1
}

#--- FUNCTION ----------------------------------------------------------------
# NAME: __strip_duplicates
# DESCRIPTION: Strip duplicate strings
#-------------------------------------------------------------------------------
__strip_duplicates() {
    echo $@ | tr -s '[:space:]' '\n' | awk '!x[$0]++'
}

#--- FUNCTION ----------------------------------------------------------------
# NAME: echoerr
# DESCRIPTION: Echo errors to stderr.
#-------------------------------------------------------------------------------
echoerror() {
    printf "${RC} * ERROR${EC}: $@\n" 1>&2;
}

#--- FUNCTION ----------------------------------------------------------------
# NAME: echoinfo
# DESCRIPTION: Echo information to stdout.
#-------------------------------------------------------------------------------
echoinfo() {
    printf "${GC} * INFO${EC}: %s\n" "$@";
}

#--- FUNCTION ----------------------------------------------------------------
# NAME: echowarn
# DESCRIPTION: Echo warning informations to stdout.
#-------------------------------------------------------------------------------
echowarn() {
    printf "${YC} * WARN${EC}: %s\n" "$@";
}

#--- FUNCTION ----------------------------------------------------------------
# NAME: echodebug
# DESCRIPTION: Echo debug information to stdout.
#-------------------------------------------------------------------------------
echodebug() {
    if [ $_ECHO_DEBUG -eq $BS_TRUE ]; then
        printf "${BC} * DEBUG${EC}: %s\n" "$@";
    fi
}

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  __apt_get_install_noinput
#   DESCRIPTION:  (DRY) apt-get install with noinput options
#-------------------------------------------------------------------------------
__apt_get_install_noinput() {
    apt-get install -y -o DPkg::Options::=--force-confold $@; return $?
}

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  __apt_get_upgrade_noinput
#   DESCRIPTION:  (DRY) apt-get upgrade with noinput options
#-------------------------------------------------------------------------------
__apt_get_upgrade_noinput() {
    apt-get upgrade -y -o DPkg::Options::=--force-confold $@; return $?
}

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  __pip_install_noinput
#   DESCRIPTION:  (DRY)
#-------------------------------------------------------------------------------
__pip_install_noinput() {
    pip install --upgrade $@; return $?
}

#---  FUNCTION  ----------------------------------------------------------------
#          NAME:  __pip_install_noinput
#   DESCRIPTION:  (DRY)
#-------------------------------------------------------------------------------
__pip_pre_install_noinput() {
    pip install --pre --upgrade $@; return $?
}

__check_apt_lock() {
    lsof /var/lib/dpkg/lock > /dev/null 2>&1
    RES=`echo $?`
    return $RES
}


__enable_universe_repository() {
    if [ "x$(grep -R universe /etc/apt/sources.list /etc/apt/sources.list.d/ | grep -v '#')" != "x" ]; then
        # The universe repository is already enabled
        return 0
    fi

    echodebug "Enabling the universe repository"

    # Ubuntu versions higher than 12.04 do not live in the old repositories
    if [ $DISTRO_MAJOR_VERSION -gt 12 ] || ([ $DISTRO_MAJOR_VERSION -eq 12 ] && [ $DISTRO_MINOR_VERSION -gt 04 ]); then
        add-apt-repository -y "deb http://archive.ubuntu.com/ubuntu $(lsb_release -sc) universe" || return 1
    elif [ $DISTRO_MAJOR_VERSION -lt 11 ] && [ $DISTRO_MINOR_VERSION -lt 10 ]; then
        # Below Ubuntu 11.10, the -y flag to add-apt-repository is not supported
        add-apt-repository "deb http://old-releases.ubuntu.com/ubuntu $(lsb_release -sc) universe" || return 1
    fi

    add-apt-repository -y "deb http://old-releases.ubuntu.com/ubuntu $(lsb_release -sc) universe" || return 1

    return 0
}

__enable_docker_repository() {
  apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
  add-apt-repository -y "deb https://apt.dockerproject.org/repo ubuntu-$(lsb_release -sc) main"
}

__check_unparsed_options() {
    shellopts="$1"
    # grep alternative for SunOS
    if [ -f /usr/xpg4/bin/grep ]; then
        grep='/usr/xpg4/bin/grep'
    else
        grep='grep'
    fi
    unparsed_options=$( echo "$shellopts" | ${grep} -E '(^|[[:space:]])[-]+[[:alnum:]]' )
    if [ "x$unparsed_options" != "x" ]; then
        usage
        echo
        echoerror "options are only allowed before install arguments"
        echo
        exit 1
    fi
}

configure_cpan() {
    (echo y;echo o conf prerequisites_policy follow;echo o conf commit)|cpan > /dev/null
}

usage() {
    echo "usage"
    exit 1
}

remove_bad_old_deps() {
    echoinfo "Removing old, conflicting, or bad packages ..."
    apt-get remove -y binplist >> $HOME/ECC-install.log 2>&1 || return 1
    apt-get remove -y unity-webapps-common  >> $HOME/ECC-install.log 2>&1 || return 1
    # This was a tzworks file, /usr/bin/id is core to determining permissions
    if [ -e /usr/local/bin/id ]; then
      rm /usr/local/bin/id
    fi
    # This is no longer a valid repo
    if [ -e /etc/apt/sources.list.d/google-chrome.list ]; then
      rm /etc/apt/sources.list.d/google-chrome.list
    fi
}

install_ubuntu_14.04_deps() {
    echoinfo "Updating your APT Repositories ... "
    apt-get update >> $HOME/ECC-install.log 2>&1 || return 1

    echoinfo "Installing Python Software Properties ... "
    __apt_get_install_noinput software-properties-common >> $HOME/ECC-install.log 2>&1  || return 1

    echoinfo "Enabling Universal Repository ... "
    __enable_universe_repository >> $HOME/ECC-install.log 2>&1 || return 1

    echoinfo "Enabling Docker Repository ... "
    __enable_docker_repository >> $HOME/ECC-install.log 2>&1 || return 1

    echoinfo "Adding Ubuntu Tweak Repository"
    add-apt-repository -y ppa:tualatrix/ppa  >> $HOME/ECC-install.log 2>&1 || return 1

    echoinfo "Adding the Oracle Java Package source"
    add-apt-repository -y ppa:webupd8team/java  >> $HOME/ECC-install.log 2>&1 || return 1

    echoinfo "Adding ECC Repository: $@"
    #add-apt-repository -y ppa:ECC/$@  >> $HOME/ECC-install.log 2>&1 || return 1

    echoinfo "Adding GIFT Repository: Stable"
    add-apt-repository -y ppa:gift/stable >> $HOME/ECC-install.log 2>&1 || return 1

    echoinfo "Updating Repository Package List ..."
    apt-get update >> $HOME/ECC-install.log 2>&1 || return 1

    echoinfo "Upgrading all packages to latest version ..."
    #__apt_get_upgrade_noinput >> $HOME/ECC-install.log 2>&1 || return 1

    return 0
}

install_ubuntu_14.04_packages() {
    packages="
build-essential
g++
gcc
git
git-core
nmap
openjdk-6-jdk
postgresql
qemu
qemu-utils
radare
radare-gtk
radare2
rar
readpst
regripper
rsakeyfind
safecopy
samba
snort
stunnel4
system-config-samba
ubuntu-tweak
unity-control-center
unrar
vbindiff
vim
virtuoso-minimal
vmfs-tools
vncviewer
wireshark
xpdf
zenity
Zenmap
"

    if [ "$@" = "dev" ]; then
        packages="$packages"
    elif [ "$@" = "stable" ]; then
        packages="$packages"
    fi

    for PACKAGE in $packages; do
        __apt_get_install_noinput $PACKAGE >> $HOME/ECC-install.log 2>&1
        ERROR=$?
        if [ $ERROR -ne 0 ]; then
            echoerror "Install Failure: $PACKAGE (Error Code: $ERROR)"
        else
            echoinfo "Installed Package: $PACKAGE"
        fi
    done

    return 0
}

install_ubuntu_14.04_pip_packages() {
    pip_packages="setuptools python-dateutil==2.4.2 distorm3 rekall docopt python-evtx python-registry six pefile analyzeMFT python-magic argparse unicodecsv stix stix-validator timesketch lxml ioc_writer colorama usnparser windowsprefetch"
    pip_pre_packages="bitstring"

    if [ "$@" = "dev" ]; then
        pip_packages="$pip_packages"
    elif [ "$@" = "stable" ]; then
        pip_packages="$pip_packages"
    fi

    ERROR=0
    for PACKAGE in $pip_pre_packages; do
        CURRENT_ERROR=0
        echoinfo "Installed Python (pre) Package: $PACKAGE"
        __pip_pre_install_noinput $PACKAGE >> $HOME/ECC-install.log 2>&1 || (let ERROR=ERROR+1 && let CURRENT_ERROR=1)
        if [ $CURRENT_ERROR -eq 1 ]; then
            echoerror "Python Package Install Failure: $PACKAGE"
        fi
    done

    for PACKAGE in $pip_packages; do
        CURRENT_ERROR=0
        echoinfo "Installed Python Package: $PACKAGE"
        __pip_install_noinput $PACKAGE >> $HOME/ECC-install.log 2>&1 || (let ERROR=ERROR+1 && let CURRENT_ERROR=1)
        if [ $CURRENT_ERROR -eq 1 ]; then
            echoerror "Python Package Install Failure: $PACKAGE"
        fi
    done

    if [ $ERROR -ne 0 ]; then
        echoerror
        return 1
    fi

    return 0
}


# Global: Works on 12.04 and 14.04
install_perl_modules() {
	# Required by macl.pl script
	perl -MCPAN -e "install Net::Wigle" >> $HOME/ECC-install.log 2>&1
}

install_burp_suite() {
  # Installing Burp suite from ECCTools Github Repository
  echoinfo "ECC tools: Installing Burp Suite"
	CDIR=$(pwd)
	git clone --recursive https://github.com/LalithaKurma/ECCTools /tmp/ECCTools >> $HOME/ECC-install.log 2>&1
	cd /tmp/ECCTools
	bash burpsuite_free_linux_v1_7_16.sh >> $HOME/ECC-install.log 2>&1
	cd $CDIR
	rm -r -f /tmp/ECCTools
}
install_ECC_files() {
  # Checkout code from ECC-files and put these files into place
  echoinfo "ECC VM: Installing ECC Files"
	CDIR=$(pwd)
	git clone --recursive https://github.com/LalithaKurma/ECC-files /tmp/ECC-files >> $HOME/ECC-install.log 2>&1
	cd /tmp/ECC-files
	bash install.sh >> $HOME/ECC-install.log 2>&1
	cd $CDIR
	rm -r -f /tmp/ECC-files
}

configure_ubuntu() {
  echoinfo "ECC VM: Creating Cases Folder"
	if [ ! -d /cases ]; then
		mkdir -p /cases
		chown $SUDO_USER:$SUDO_USER /cases
		chmod 775 /cases
		chmod g+s /cases
	fi

  echoinfo "ECC VM: Creating Mount Folders"
	for dir in usb vss shadow windows_mount e01 aff ewf bde iscsi
	do
		if [ ! -d /mnt/$dir ]; then
			mkdir -p /mnt/$dir
		fi
	done

	for NUM in 1 2 3 4 5
	do
		if [ ! -d /mnt/windows_mount$NUM ]; then
			mkdir -p /mnt/windows_mount$NUM
		fi
		if [ ! -d /mnt/ewf_mount$NUM ]; then
			mkdir -p /mnt/ewf_mount$NUM
		fi
	done
 
	for NUM in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30
	do
		if [ ! -d /mnt/shadow/vss$NUM ]; then
			mkdir -p /mnt/shadow/vss$NUM
		fi
		if [ ! -d /mnt/shadow_mount/vss$NUM ]; then
			mkdir -p /mnt/shadow_mount/vss$NUM
		fi
	done

  echoinfo "ECC VM: Setting up symlinks to useful scripts"
  if [ ! -L /usr/bin/vol.py ] && [ ! -e /usr/bin/vol.py ]; then
    ln -s /usr/bin/vol.py /usr/bin/vol
	fi
	if [ ! -L /usr/bin/log2timeline ] && [ ! -e /usr/bin/log2timeline ]; then
		ln -s /usr/bin/log2timeline_legacy /usr/bin/log2timeline
	fi
	if [ ! -L /usr/bin/kedit ] && [ ! -e /usr/bin/kedit ]; then
		ln -s /usr/bin/gedit /usr/bin/kedit
	fi
	if [ ! -L /usr/bin/mount_ewf.py ] && [ ! -e /usr/bin/mount_ewf.py ]; then
		ln -s /usr/bin/ewfmount /usr/bin/mount_ewf.py
	fi

  # Fix for https://github.com/sans-dfir/ECC/issues/10
  if [ ! -L /usr/bin/icat-sleuthkit ] && [ ! -e /usr/bin/icat-sleuthkit ]; then
    ln -s /usr/bin/icat /usr/bin/icat-sleuthkit 
  fi

  # Fix for https://github.com/sans-dfir/ECC/issues/23
  if [ ! -L /usr/local/bin/l2t_process ] && [ ! -e /usr/local/bin/l2t_process ]; then
    ln -s /usr/bin/l2t_process_old.pl /usr/local/bin/l2t_process
  fi

  if [ ! -L /usr/local/etc/foremost.conf ]; then
    ln -s /etc/foremost.conf /usr/local/etc/foremost.conf
  fi

  # Fix for https://github.com/sans-dfir/ECC/issues/41
  if [ ! -L /usr/local/bin/mactime-sleuthkit ] && [ ! -e /usr/local/bin/mactime-sleuthkit ]; then
    ln -s /usr/bin/mactime /usr/local/bin/mactime-sleuthkit
  fi

  sed -i "s/APT::Periodic::Update-Package-Lists \"1\"/APT::Periodic::Update-Package-Lists \"0\"/g" /etc/apt/apt.conf.d/10periodic
}

# Global: Ubuntu ECC VM Configuration Function
# Works with 12.04 and 14.04 Versions
configure_ubuntu_ECC_vm() {
  echoinfo "ECC VM: Setting Hostname: ECCworkstation"
	OLD_HOSTNAME=$(hostname)
	sed -i "s/$OLD_HOSTNAME/ECCworkstation/g" /etc/hosts
	echo "ECCworkstation" > /etc/hostname
	hostname ECCworkstation

  echoinfo "ECC VM: Fixing Samba User"
	# Make sure we replace the ECC_USER template with our actual
	# user so there is write permissions to samba.
	sed -i "s/ECC_USER/$SUDO_USER/g" /etc/samba/smb.conf

  echoinfo "ECC VM: Restarting Samba"
	# Restart samba services 
	service smbd restart >> $HOME/ECC-install.log 2>&1
	service nmbd restart >> $HOME/ECC-install.log 2>&1

  echoinfo "ECC VM: Setting Timezone to UTC" >> $HOME/ECC-install.log 2>&1
  echo "Etc/UTC" > /etc/timezone >> $HOME/ECC-install.log 2>&1
    
  echoinfo "ECC VM: Fixing Regripper Files"
	# Make sure to remove all ^M from regripper plugins
	# Not sure why they are there in the first place ...
	dos2unix -ascii /usr/share/regripper/* >> $HOME/ECC-install.log 2>&1

  if [ -f /usr/share/regripper/plugins/usrclass-all ]; then
    mv /usr/share/regripper/plugins/usrclass-all /usr/share/regripper/plugins/usrclass
  fi

  if [ -f /usr/share/regripper/plugins/ntuser-all ]; then
    mv /usr/share/regripper/plugins/ntuser-all /usr/share/regripper/plugins/ntuser
  fi

  chmod 775 /usr/share/regripper/rip.pl
  chmod -R 755 /usr/share/regripper/plugins
    
  echoinfo "ECC VM: Setting noclobber for $SUDO_USER"
	if ! grep -i "set -o noclobber" $HOME/.bashrc > /dev/null 2>&1
	then
		echo "set -o noclobber" >> $HOME/.bashrc
	fi
	if ! grep -i "set -o noclobber" /root/.bashrc > /dev/null 2>&1
	then
		echo "set -o noclobber" >> /root/.bashrc
	fi

  echoinfo "ECC VM: Configuring Aliases for $SUDO_USER and root"
	if ! grep -i "alias mountwin" $HOME/.bash_aliases > /dev/null 2>&1
	then
		echo "alias mountwin='mount -o ro,loop,show_sys_files,streams_interface=windows'" >> $HOME/.bash_aliases
	fi
	
	# For ECC VM, root is used frequently, set the alias there too.
	if ! grep -i "alias mountwin" /root/.bash_aliases > /dev/null 2>&1
	then
		echo "alias mountwin='mount -o ro,loop,show_sys_files,streams_interface=windows'" >> /root/.bash_aliases
	fi

  echoinfo "ECC VM: Sanity check for Desktop folder"
        if [ ! -d $HOME/Desktop ]; then
                sudo -u $SUDO_USER mkdir -p $HOME/Desktop
        fi
  
  echoinfo "ECC VM: Setting up useful links on $SUDO_USER Desktop"
	if [ ! -L $HOME/Desktop/cases ]; then
		sudo -u $SUDO_USER ln -s /cases $HOME/Desktop/cases
	fi
  
	if [ ! -L $HOME/Desktop/mount_points ]; then
		sudo -u $SUDO_USER ln -s /mnt $HOME/Desktop/mount_points
	fi

  echoinfo "ECC VM: Cleaning up broken symlinks on $SUDO_USER Desktop"
	# Clean up broken symlinks
	find -L $HOME/Desktop -type l -delete

  echoinfo "ECC VM: Adding all ECC Resources to $SUDO_USER Desktop"
	for file in /usr/share/ECC/resources/*.pdf
	do
		base=`basename $file`
		if [ ! -L $HOME/Desktop/$base ]; then
			sudo -u $SUDO_USER ln -s $file $HOME/Desktop/$base
		fi
	done

  if [ ! -L /sbin/iscsiadm ]; then
    ln -s /usr/bin/iscsiadm /sbin/iscsiadm
  fi
  
  if [ ! -L /usr/local/bin/rip.pl ]; then
    ln -s /usr/share/regripper/rip.pl /usr/local/bin/rip.pl
  fi

  # Add extra device loop backs.
  if ! grep "do mknod /dev/loop" /etc/rc.local > /dev/null 2>&1
  then
    echo 'for i in `seq 8 100`; do mknod /dev/loop$i b 7 $i; done' >> /etc/rc.local
  fi
}

# 14.04 ECC VM Configuration Function
configure_ubuntu_14.04_ECC_vm() {
  sudo -u $SUDO_USER gsettings set com.canonical.Unity.Launcher favorites "['application://nautilus.desktop', 'application://gnome-terminal.desktop', 'application://firefox.desktop', 'application://gnome-screenshot.desktop', 'application://gcalctool.desktop', 'application://bless.desktop', 'application://autopsy.desktop', 'application://wireshark.desktop']" >> $HOME/ECC-install.log 2>&1

  # Works in 12.04 and 14.04
  sudo -u $SUDO_USER gsettings set org.gnome.desktop.background picture-uri file:///usr/share/ECC/images/forensics_blue.jpg >> $HOME/ECC-install.log 2>&1

  # Works in 14.04 
	if [ ! -d $HOME/.config/autostart ]; then
		sudo -u $SUDO_USER mkdir -p $HOME/.config/autostart
	fi

  # Works in 14.04 too.
	if [ ! -L $HOME/.config/autostart ]; then
		sudo -u $SUDO_USER cp /usr/share/ECC/other/gnome-terminal.desktop $HOME/.config/autostart
	fi
    
  # Works in 14.04 too
	if [ ! -e /usr/share/unity-greeter/logo.png.ubuntu ]; then
		sudo cp /usr/share/unity-greeter/logo.png /usr/share/unity-greeter/logo.png.ubuntu
		sudo cp /usr/share/ECC/images/login_logo.png /usr/share/unity-greeter/logo.png
	fi

  # Setup user favorites (only for 12.04)
  sudo -u $SUDO_USER dconf write /desktop/unity/launcher/favorites "['nautilus.desktop', 'gnome-terminal.desktop', 'firefox.desktop', 'gnome-screenshot.desktop', 'gcalctool.desktop', 'bless.desktop', 'autopsy.desktop', 'wireshark.desktop']" >> $HOME/ECC-install.log 2>&1

  # Setup the login background image
  cp /usr/share/ECC/images/forensics_blue.jpg /usr/share/backgrounds/warty-final-ubuntu.png
  
  chown -R $SUDO_USER:$SUDO_USER $HOME
}

complete_message() {
    echo
    echo "Installation Complete!"
    echo 
    echo "The documentation is always a work in progress, feel free to contribute!"
    echo "Fork the ECC-docs project and start sending your pull requests today."
    echo 
    echo "Documentation: http://ECC.readthedocs.org"
    echo
}

complete_message_skin() {
    echo "The hostname was changed, you should relogin or reboot for it to take full effect."
    echo
    echo "sudo reboot"
    echo
}

UPGRADE_ONLY=0
CONFIGURE_ONLY=0
SKIN=0
INSTALL=1
YESTOALL=0

OS=$(lsb_release -si)
ARCH=$(uname -m | sed 's/x86_//;s/i[3-6]86/32/')
VER=$(lsb_release -sr)

if [ $OS != "Ubuntu" ]; then
    echo "ECC-CEH is only installable on Ubuntu operating systems at this time."
    exit 1
fi

if [ $ARCH != "64" ]; then
    echo "ECC-CEH is only installable on a 64 bit architecture at this time."
    exit 2
fi

if [ $VER != "14.04" ]; then
    echo "ECC-CEH is only installable on Ubuntu 14.04 at this time."
    exit 3
fi

if [ `whoami` != "root" ]; then
    echoerror "The ECC-CEH Bootstrap script must run as root."
    echoinfo "Preferred Usage: sudo bootstrap.sh (options)"
    echo ""
    exit 3
fi

if [ "$SUDO_USER" = "" ]; then
    echo "The SUDO_USER variable doesn't seem to be set"
    exit 4
fi

#if [ ! "$(__check_apt_lock)" ]; then
#    echo "APT Package Manager appears to be locked. Close all package managers."
#    exit 15
#fi

while getopts ":hvcsiyu" opt
do
case "${opt}" in
    h ) usage; exit 0 ;;  
    v ) echo "$0 -- Version $__ScriptVersion"; exit 0 ;;
    s ) SKIN=1 ;;
    i ) INSTALL=1 ;;
    c ) CONFIGURE_ONLY=1; INSTALL=0; SKIN=0; ;;
    u ) UPGRADE_ONLY=1; ;;
    y ) YESTOALL=1 ;;
    \?) echo
        echoerror "Option does not exist: $OPTARG"
        usage
        exit 1
        ;;
esac
done

shift $(($OPTIND-1))

if [ "$#" -eq 0 ]; then
    ITYPE="stable"
else
    __check_unparsed_options "$*"
    ITYPE=$1
    shift
fi

if [ "$UPGRADE_ONLY" -eq 1 ]; then
  echoinfo "ECC-CEH Update"
  echoinfo "All other options will be ignored!"
  echoinfo "This could take a few minutes ..."
  echo ""
  
  export DEBIAN_FRONTEND=noninteractive

  remove_bad_old_deps || echoerror "Removing Old Depedencies Failed"
  install_ubuntu_${VER}_deps $ITYPE || echoerror "Updating Depedencies Failed"
  install_ubuntu_${VER}_packages $ITYPE || echoerror "Updating Packages Failed"
  install_ubuntu_${VER}_pip_packages $ITYPE || echoerror "Updating Python Packages Failed"
  install_perl_modules || echoerror "Updating Perl Packages Failed"
  install_ECC_files || echoerror "Installing/Updating ECC-CEH Files Failed"

  echo ""
  echoinfo "ECC-CEH Upgrade Complete"
  exit 0
fi

# Check installation type
if [ "$(echo $ITYPE | egrep '(dev|stable)')x" = "x" ]; then
    echoerror "Installation type \"$ITYPE\" is not known..."
    exit 1
fi

echoinfo "Welcome to the ECC-CEH Bootstrap"
echoinfo "This script will now proceed to configure your system."

if [ "$YESTOALL" -eq 1 ]; then
    echoinfo "You supplied the -y option, this script will not exit for any reason"
fi

echoinfo "OS: $OS"
echoinfo "Arch: $ARCH"
echoinfo "Version: $VER"

if [ "$SKIN" -eq 1 ] && [ "$YESTOALL" -eq 0 ]; then
    echo
    echo "You have chosen to apply the ECC-CEH skin to your ubuntu system."
    echo 
    echo "You did not choose to say YES to all, so we are going to exit."
    echo
    echo "Your current user is: $SUDO_USER"
    echo
    echo "Re-run this command with the -y option"
    echo
    exit 10
fi

if [ "$INSTALL" -eq 1 ] && [ "$CONFIGURE_ONLY" -eq 0 ]; then
    export DEBIAN_FRONTEND=noninteractive
    install_ubuntu_${VER}_deps $ITYPE
    install_ubuntu_${VER}_packages $ITYPE
    install_ubuntu_${VER}_pip_packages $ITYPE
    #Calling to install burpsuite package    
    install_burp_suite
    configure_cpan
    install_perl_modules
    install_ECC_files
fi

# Configure for ECC
configure_ubuntu

# Configure ECC VM (if selected)
if [ "$SKIN" -eq 1 ]; then
    configure_ubuntu_ECC_vm
    configure_ubuntu_${VER}_ECC_vm
fi

complete_message

if [ "$SKIN" -eq 1 ]; then
    complete_message_skin
fi
