# A Portable Classroom Linux Server on the BeagleBone Black

By: Johan Nylander, BILS

Version: August 2015


## Description

This document describes the installation of Ubuntu Linux ([ubuntu-armhf distribution](http://www.armhf.com/index.php/boards/beaglebone-black/)) on a [BeagleBone Black](http://beagleboard.org/Products/BeagleBone+Black), and the configuration of a portable classroom Linux server (named *Black*) that runs a private WiFi network. Parts of this documentation is compiled from other sources (see list at the end).


## Some info

Default user/passwd on the ubuntu-armhf distro:

    hostname: ubuntu-armhf
    username: ubuntu
    password: ubuntu

Admin user/passwd on the finished BeagleBone Black box:

    Hostname: black
    IP on private LAN: 10.0.0.1
    Admin username: bbb
    Password:
    WiFi SSID/WPA passphrase: Mr.Black
    URL: http://10.0.0.1


## Install image on SD card

Run these steps on your local computer having a card reader. Tested on 64bit Xubuntu 13.10.


#### Become root

    sudo su -
    mkdir -p $HOME/tmp/bbb
    cd $HOME/tmp/bbb


#### Check device name

Check device name by looking at what appears before and after plugging in the sd card in your computer

    ls -lah /dev/sd* /dev/mmcb*

Plug in sd card

    ls -lah /dev/sd* /dev/mmcb*
     
Look for your device, e.g., `/dev/mmcblk0`, not(!) the partition (e.g., `/dev/mmcblk0p1`)


#### Get armhf image

Image accessed March 2014. Revisit [http://www.armhf.com/index.php/download](http://www.armhf.com/index.php/download) to check for latest images.

    wget http://s3.armhf.com/debian/saucy/bone/ubuntu-saucy-13.10-armhf-3.8.13-bone30.img.xz


#### Unpack and write image

    apt-get install xz-utils
    xz -cd ubuntu-saucy-13.10-armhf-3.8.13-bone30.img.xz > /dev/mmcblk0


#### Partprobe

    partprobe /dev/mmcblk0


#### Check that we have two partitions

    ls -la /dev/mmcblk0*


#### Mount, sync, umount

    mkdir /media/b1 /media/b2
    mount /dev/mmcblk0p1 /media/b1
    mount /dev/mmcblk0p2 /media/b2
    sync
    umount /dev/mmcblk0p1
    umount /dev/mmcblk0p2
    rmdir /media/b1 /media/b2


#### Eject sd card

You now have, hopefully, a bootable Linux distro on your sd card.


## Install image on BeagleBoneBlack.

I connected a screen to the BBB via the HDMI, a USB-hub with external power source to the USB, and in the USB hub I connected a mouse, keyboard, and a USB WiFi adapter (Asus N53).


### Boot your image

Insert sd card in the BBB, and boot while pressing the boot button.

**NOTE**: The BBB will try to boot the internal Angstrom image by default. To boot from microSD, you'll need to hold down the USER/BOOT button (located near the microSD end of the board) while powering-on the device.


### Logon to ubuntu-armhf

Logon to ubuntu-armhf as user `ubuntu` with password `ubuntu`


### Change keyboard layout if necessary

    sudo loadkeys se


### Write to Internal eMMC

**NOTE**: This step will *owerwrite* what you have on the internal drive on your BBB!

"The prebuilt image is sized to exactly 1832MB to allow it to fit into the BeagleBone Black's on-board 2GB NAND storage. This size also allows it to fit on a wide variety of external microSD cards. The image can be resized to take advantage of additional space available on larger microSD cards. To install the image to the internal eMMC, boot from the SD card. While booted from an external SD card, the internal eMMC will be available as `/dev/mmcblk1`."

To write the image to eMMC, execute:

    wget http://s3.armhf.com/debian/saucy/bone/ubuntu-saucy-13.10-armhf-3.8.13-bone30.img.xz
    sudo su -
    cd /home/ubuntu
    xz -cd ubuntu-saucy-13.10-armhf-3.8.13-bone30.img.xz > /dev/mmcblk1


### Boot from eMMC

Try to boot from the new ubuntu-armhf on your eMMC

    shutdown -h now

When the BBB is powered down, remove the sd card and power it up again. If all worked well, you should be greeted by a login prompt saying `ubuntu-armhf login: _`


## Configuration


### Logon to ubuntu-armhf

Logon to ubuntu-armhf as user `ubuntu` with a password `ubuntu`


### Change keyboard layout if necessary

    sudo loadkeys se

If you need to apply this change permanently, run

    sudo setupcon --save

Other ways to (permanently) change keyboard layout and TTY fonts etc are by using `sudo dpkg-reconfigure keyboard-configuration` and `sudo dpkg-reconfigure console-setup`.


### Upgrade

    sudo apt-get update
    sudo apt-get upgrade


### Install some software
    
    sudo apt-get install vim git dnsmasq iw hostapd curl psmisc

Add your own here

    sudo apt-get install ncbi-blast+ muscle

And add this file

    git clone git://github.com/nylander/BBB.git
    

#### Change host name

Change the host name `ubuntu-armhf` to `black`

    sudo sed -i.bkp -e 's/ubuntu-armhf/black' /etc/hostname
    sudo sed -i.bkp -e 's/ubuntu-armhf/black' /etc/hosts
    sudo service hostname restart   # If not working, do reboot below
    sudo shutdown -r now


### Install and configure webserver


#### Add some default files

    sudo cp -r $HOME/BBB/www/* /var/www


#### Install the [lighttpd](http://www.lighttpd.net) webserver

    sudo apt-get install lighttpd


#### Configure

Add these lines to your `/etc/lighttpd/lighttpd.conf` file

    dir-listing.activate = "enable"
    dir-listing.show-header = "enable"
    dir-listing.encode-header = "disable"
    dir-listing.hide-header-file = "enable"
    dir-listing.set-footer = "This is the BBB server."
    # more options here


Enable public user web directories (`http://10.0.0.1/~userNN`)

    sudo lighttpd-enable-mod userdir


Remove default index page

    sudo rm /var/www/index.lighttpd.html


Restart the webserver

    sudo service lighttpd reload


### WiFi-broadcasting

**NOTE**: "You will also want to do a survey of your area to find the channel that has the fewest other APs on it. When choosing which channel to use, it is important to remember that the channels overlap with any channels that are within 20MHz."
See also [wireless.kernel.org](http://wireless.kernel.org/en/users/Documentation/acs#Hostapd_setup).

For automated channel selection, try to add (in `hostapd.conf`): `CONFIG_ACS=y` and `channel=acs_survey`. (**NOTE**: didn't work 2014-Mar-14)

We will start by setting up an open network to prevent connection problems. Take necessary precautions (e.g., setting `wpa=3`) if using a bridged network.

#### Create the file `/etc/hostapd/hostapd.conf` with the follow content:

    interface=wlan0
    driver=nl80211
    ssid=Mr.Black
    hw_mode=g
    channel=6
    macaddr_acl=0
    auth_algs=1
    ignore_broadcast_ssid=0
    wpa=0
    wpa_passphrase=Mr.Black
    wpa_key_mgmt=WPA-PSK
    wpa_pairwise=TKIP
    rsn_pairwise=CCMP


#### Edit `/etc/default/hostapd` to have the line:

    DAEMON_CONF=/etc/hostapd/hostapd.conf


Setup dnsmasq to handle DHCP and DNS on our wifi network, otherwise your clients won't be able to get an IP address:

#### Edit the dnsmasq configuration file `/etc/dnsmasq.conf` to include this:

    interface=wlan0
    dhcp-range=10.0.0.2,10.0.0.50,12h
    no-hosts
    addn-hosts=/etc/hosts.dnsmasq


We set `no-hosts` to avoid including all the entries in your hosts file in the DNS server, and instead set a separate file that will configure the DNS mapping for the machine hosting the AP.

#### Create the file `/etc/hosts.dnsmasq` with the name of your computer:

    10.0.0.1 black


#### Add these lines to your `/etc/network/interfaces` file, to give it a static IP address:
        
    auto wlan0
    iface wlan0 inet static
    address 10.0.0.1
    netmask 255.255.255.0

If you have network-manager configured to use your wifi card, you should disable auto-connect for all the wireless connections. Otherwise, it may interfere with hostapd.

**NOTE**: In order to have the BBB boot as a bare-bone machine (only power adapter and USB-WiFi dongle connected), I had to comment out the `auto eth0` and `iface eth0 inet dhcp` I had in my `/etc/network/interfaces` file, then reboot. If you want to connect to the BBB using an ethernet cable, those lines have to be enabled again.

### Add files to `/etc/skel`

Add your own files (that all new users should have in their home folders) to `/etc/skel` before creating new users.

    sudo cp -r $HOME/BBB/skel/* /etc/skel


### Change user permissions and add users.


#### Add new admin user

Add new admin user (in group sudo). **NOTE**: need to provide `password`

    pass=$(perl -e 'print crypt("password", "salt")')
    sudo useradd -m -G sudo -p "$pass" -s /bin/bash bbb

**NOTE**: please make sure this user (`bbb`) can login and perform `sudo` commands before proceeding.


#### Add users

Add N users (`user00`, `user01`, ..., `userN`) with the same password `catboxyellow`. We'll start with N=20.

    pass=$(perl -e 'print crypt("catboxyellow", "salt")')
    for u in $(seq -w 0 20); do sudo useradd -m -p "$pass" -s /bin/bash user${u}; done

If you need a random (component) to your password, look at the [create_users.sh](users/create_users.sh) script.


#### Disable the default user

Disable (lock) the default user `ubuntu`. To unlock, use `-u`.

**NOTE**: After this you can no longer login with the user `ubuntu`.

    sudo passwd -l ubuntu


### TODO

* WiFi alternatives for bridged settings (plug an ethernet cable in BBB, and let it share its' internet connection).

* Utilize space on external microSD card.


### Sources

I took information and some text from these sources (March 2014):

[http://analogdigitallab.org/blogs/beaglebone-black-webserver-running-ubuntu](http://analogdigitallab.org/blogs/beaglebone-black-webserver-running-ubuntu)

[http://cberner.com/2013/02/03/using-hostapd-on-ubuntu-to-create-a-wifi-access-point](http://cberner.com/2013/02/03/using-hostapd-on-ubuntu-to-create-a-wifi-access-point)

[http://dotnetdavid.wordpress.com/2013/09/13/beaglebone-black-installing-ubuntu-part-2](http://dotnetdavid.wordpress.com/2013/09/13/beaglebone-black-installing-ubuntu-part-2)

[http://sirlagz.net/2012/08/10/how-to-use-the-raspberry-pi-as-a-wireless-access-pointrouter-part-2](http://sirlagz.net/2012/08/10/how-to-use-the-raspberry-pi-as-a-wireless-access-pointrouter-part-2)

[http://wireless.kernel.org/en/users/Documentation/acs](http://wireless.kernel.org/en/users/Documentation/acs)

[http://wireless.kernel.org/en/users/Documentation/hostapd](http://wireless.kernel.org/en/users/Documentation/hostapd)

[http://www.armhf.com/index.php/boards/beaglebone-black](http://www.armhf.com/index.php/boards/beaglebone-black)

[http://www.danbishop.org/2011/12/11/using-hostapd-to-add-wireless-access-point-capabilities-to-an-ubuntu-server](http://www.danbishop.org/2011/12/11/using-hostapd-to-add-wireless-access-point-capabilities-to-an-ubuntu-server)

[https://help.ubuntu.com/community/WifiDocs/MasterMode](https://help.ubuntu.com/community/WifiDocs/MasterMode)

[https://help.ubuntu.com/community/lighttpd](https://help.ubuntu.com/community/lighttpd)


