; Copyright 2015 Mike Swierczek
; This program is free software: you can redistribute it and/or modify
;   it under the terms of the GNU General Public License as published by
;   the Free Software Foundation, either version 3 of the License, or
;   (at your option) any later version.

;   This program is distributed in the hope that it will be useful,
;   but WITHOUT ANY WARRANTY; without even the implied warranty of
;   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;   GNU General Public License for more details.

;   You should have received a copy of the GNU General Public License
;   along with this program.  If not, see <http://www.gnu.org/licenses/>.


; Simple script to update DNS entries in resolv.conf
; after an OpenVPN connection is established.
;
; This has been tested on Ubuntu and Fedora Linux 
; with SBCL installed.  
; You can use the included vpn.sh shell script
; as a starting point.
;
; Author's note - this is my first attempt to write 
; anything in Lisp more complicated than "Hello World".
; There is almost certainly un-idiomatic Lisp code
; and bad practices here.  
;
; This code has been tested with SBCL, it may
; be compatible with other Lisp distributions, I don't know.
; 
; 

(write-line "OpenVPN DNS fixup started.")

; *posix-argv* is the command line arguments in 
; SBCL
;(mapcar (function write-line) *posix-argv*)

(if (> 2 (length *posix-argv*))
    (progn
       (write-line "You have to put \"start\" or \"stop\" on the command line.")
       (exit)))

(defparameter *option* (cadr *posix-argv*))

(write-line (concatenate 'string "Received option \"" *option* "\"."))

(if (not (or (string= "stop" (string-downcase *option*))
             (string= "start" (string-downcase *option*))))
    (progn
       (write-line "Option not recognized, expected \"start\" or \"stop\".")
       (exit)))

; This function was taken from The Common Lisp Cookbook and is 
; assumed to be freely usable.  http://cl-cookbook.sourceforge.net/os.html
; If that is not the case, please contact me and I will remove it.
(defun my-getenv (name &optional default)
    #+CMU   
    (let ((x (assoc name ext:*environment-list*
                    :test #'string=)))
      (if x (cdr x) default))
    #-CMU   
    (or
     #+Allegro (sys:getenv name)
     #+CLISP (ext:getenv name)
     #+ECL (si:getenv name)
     #+SBCL (sb-unix::posix-getenv name)
     #+LISPWORKS (lispworks:environment-variable name)
     default))

; OpenVPN supplies DHCP options to the client that get 
; fed to the script as environment variables, each named
; foreign_option_X where X is a number, starting at 1.
; The foreign_option_X values are in the format dhcp-option DNS .....
; or dhcp-option DOMAIN .....  This program only manages DNS.
(defun getdhcpdnsoptions () (loop for x from 1 to 30
       for y = (my-getenv
                   (concatenate 'string "foreign_option_" (write-to-string x)))
          if (and (and (not (null y)) (string= "dhcp-option DNS" (subseq y 0 15)))
               (< 22 (length y)))
          collect (concatenate 'string "nameserver " (subseq y 16))))

; Simple file copy.  I made it binary just because I could, it's modifying text
; files so that was not necessary.
(defun copyfile (src dest) 
       (with-open-file (stream src :if-does-not-exist :error :element-type '(unsigned-byte 8))
          (with-open-file (outstream dest :direction :output :if-exists :supersede :element-type '(unsigned-byte 8))
          (loop for item = (read-byte stream nil)
              until (null item)
              do (write-byte item outstream))))
       t)

; I wanted simpler error messages - a Lisp guru would want the whole stacktrace,
; but then a Lisp guru could write a better version in ten minutes. 
(defun niceerrorcopyfile (src dest)
   (handler-case (copyfile src dest)
       (t (someerror) 
          (progn
              (write-line "There was an error copying the file - do you have the right permissions?")
              (write-line "Maybe you need to be root or use sudo?")
              nil))))

; in contrast to the file copy, the write uses text handling.
(defun writefile (filename contents)
    (with-open-file (outstream filename :direction :output :if-exists :supersede)
        (loop for item in contents
            do (write-line item outstream)))
    t)

(defun niceerrorwritefile (filename contents) 
   (handler-case (writefile filename contents)
       (t (someerror)
          (progn
             (write-line "There was an error writing the file - do you have the right permissions?")
             (write-line "Maybe you need to be root or use sudo?")
             (print someerror)
             nil))))

; the meat of the program
(if (string= "stop" *option*) 
   (progn
      (write-line "Stop received, attempting to restore previous DNS.")
      (if (niceerrorcopyfile "/etc/resolv.conf.backup" "/etc/resolv.conf")
          (write-line "Finished")))
   (progn
      (write-line "Start received. Attempting to get DNS entries from")
      (write-line "Environment variables.")
      (let ((dnslist (getdhcpdnsoptions))) 
         (if (null dnslist)
            (progn
               (write-line "No DNS options were received from input.")
               (write-line "Expected environment variables in the form.")
               (write-line "foreign_option_1 = DNS 1.2.3.4 ")
               (write-line "foreign_option_2 = DNS 1.2.3.5 "))
            (progn
               (write-line "Received: ")
               (mapcar (function write-line) dnslist)
               (write-line "Attempting to backup previous DNS.")
               (if (niceerrorcopyfile "/etc/resolv.conf" "/etc/resolv.conf.backup")
                    (write-line "Backed up previous DNS.")
                    ) 
               (if (niceerrorwritefile "/etc/resolv.conf" 
                        (cons "#Generated by Simple DNS fixup for OpenVPN" dnslist))
                    (write-line "Finished")))))))
