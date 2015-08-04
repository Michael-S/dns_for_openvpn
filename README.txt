This simple Lisp script works with OpenVPN for Linux
to set up VPN settings.  There are open source shell
scripts for accomplishing the same task, I just
wanted to write a Lisp version as a learning
exercise.

To use, you must have SBCL Lisp installed as
well as OpenVPN.
On Debian, Ubuntu, and other similar versions using the 
apt tool:
sudo apt-get install sbcl openvpn 
(or just as root) apt-get install sbcl openvpn

On Fedora 21 and other versions using the yum tool:
sudo yum install sbcl openvpn 
(or just as root) yum install sbcl openvpn
On Fedora 22 and later versions using the dnf tool:
sudo dnf install sbcl openvpn
(or just as root) dnf install sbcl openvpn

Put the file dns_with_openvpn.lisp into your /root
directory. For the command line of your  
your OpenVPN connection, add these input parameters:  
--script-security 2
up "/usr/bin/sbcl --script /root/dns_with_openvpn.lisp start"
down "/usr/bin/sbcl --script /root/dns_with_openvpn.lisp stop"

That should be it.
Thank you to the people maintaining SBCL and the Common Lisp 
Cookbook, and to Conrad Barski for his excellent "Land of Lisp" book.


