#!/bin/bash
############################################################################
# ModemStat -- Version 2.0
#
# Runs a series of diagnostic tests on the modem to determine what the
#
# - Signal strength is
# - Network registration state
# - SIM state (Pin Lock / Blocked / other error )
# - Service level available and Selected (GPRS/3G/etc..)
# - Modem Type / IMEI / SIM Nunber/ Firmware version
#
# Copyright (c) 2016-2021 Andrew O'Connell and others
# 
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
# 
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
# 
############################################################################

if [[ "$1" == "-q" ]] 
then 
	OUTPUT=1
else	
	OUTPUT=0
fi


#################### MODEM VENDOR CHECK

if [[ ${OUTPUT} -eq 0 ]] 
then 
	echo -en "Modem Vendor                       : "
else
	echo -en "MODEMVENDOR="
fi

chat -Vs TIMEOUT 10 ECHO OFF "" "ATI5" "OK" >/dev/modemAT </dev/modemAT 2>/tmp/log

REGEX_SIMCOM='.*SIMCOM.*'
REGEX_QUECTEL='.*Quectel.*'
REGEX_SIERRA='.*Sierra.*'

RESPONSE=$(</tmp/log)

if [[ $RESPONSE =~ $REGEX_QUECTEL ]] ; then
	MODEM=1   # QUECTEL
	echo "QUECTEL"
elif [[ $RESPONSE =~ $REGEX_SIMCOM ]] ; then
	MODEM=2   # SIMCOM/OTHER:
	echo "SIMCOM"
elif [[ $RESPONSE =~ $REGEX_SIERRA ]] ; then
	MODEM=3   # SIERRA WIRELESS
	echo "SIERRA WIRELESS"
else	
	MODEM=0   # UNKNOWN
	echo "UNKNOWN"
fi

#################### MODEM IMEI NUMBER

if [[ ${OUTPUT} -eq 0 ]] 
then 
	echo -en "Modem IMEI Number                  : "
else
	echo -en "IMEI="
fi
	
chat -Vs TIMEOUT 10 ECHO OFF "" "AT+CIMI" "OK" >/dev/modemAT </dev/modemAT 2>/tmp/log

REGEX='^([0-9]+)$'
RESPONSE=`cat /tmp/log | head -n -1 | tail -n +2 | grep -v '^[[:space:]]*$'`

IMEI=""

if [[ $RESPONSE =~ $REGEX ]]
then
		IMEI="${BASH_REMATCH[1]}"                        
fi

echo $IMEI

#################### SIM NUMBER

# Doesn't work on Sierra Wireless Modems
if [[ $MODEM != 3 ]]
then
	if [[ ${OUTPUT} -eq 0 ]] 
	then 
		echo -en "SIM ID Number                      : "
	else
		echo -en "SIM="
	fi


	chat -Vs TIMEOUT 10 ECHO OFF "" "AT+CCID" "OK" >/dev/modemAT </dev/modemAT 2>/tmp/log

	REGEX='\+CCID: ([0-9]+)'
	RESPONSE=$(</tmp/log)

	SIMID=""

	if [[ $RESPONSE =~ $REGEX ]]
	then
			SIMID="${BASH_REMATCH[1]}"                        
	fi

	echo $SIMID
fi

#################### SIM &  PIN CHECK


if [[ ${OUTPUT} -eq 0 ]] 
then 
echo -en "SIM Status                         : "	
else
	echo -en "SIMSTATUS="
fi

chat -Vs TIMEOUT 10 ECHO OFF "" "AT+CPIN?" "OK" >/dev/modemAT </dev/modemAT 2>/tmp/log

REGEX='\+CPIN:.([a-zA-Z]*)'
RESPONSE=$(</tmp/log)

CPIN=""

if [[ $RESPONSE =~ $REGEX ]]
then
        CPIN="${BASH_REMATCH[1]}"
fi

if [[ ${OUTPUT} -eq 0 ]] 
then 
	if [[ $CPIN == "READY"   ]]; then
		echo "SIM unlocked and ready";
	elif [[ $CPIN == "SIM PIN" ]]; then
		echo "SIM PIN LOCKED - MUST DEACTIVATE BEFORE USE WITH SYSTEM";
	elif [[ $CPIN == "SIM PUK" ]]; then
		echo "SIM LOCKED BY NETWORK OPERATOR - MUST DEACTIVATE BEFORE USE WITH SYSTEM";
	elif [[ $CPIN == "BLOCKED" ]]; then
		echo "LOCKED BY NETWORK OPERATOR - MUST DEACTIVATE BEFORE USE WITH SYSTEM\n";
	elif [[ $CPIN == "PH-NET PIN" ]]; then
		echo "MODEM LOCKED BY NETWORK OPERATOR - MUST DEACTIVATE BEFORE USE WITH SYSTEM";
	else
		echo " ** Infomation Not Available **"
	fi
else
	echo "'${CPIN}'"
fi






#################### SIGNAL QUALITY

if [[ ${OUTPUT} -eq 0 ]] 
then 
	echo -en "Signal Quality                     : "
else
	echo -en "SIGNAL="
fi

chat -Vs TIMEOUT 10 ECHO OFF "" "AT+CSQ" "OK" >/dev/modemAT </dev/modemAT 2>/tmp/log

REGEX='\CSQ: ([0-9]*),([0-9]*)'
RESPONSE=$(</tmp/log)

CSQ1=""
CSQ2=""


if [[ $RESPONSE =~ $REGEX ]]
then
        CSQ1="${BASH_REMATCH[1]}"
        CSQ2="${BASH_REMATCH[2]}"
fi

if [[ ${OUTPUT} -eq 0 ]] 
then 
	echo "${CSQ1}/32"
else
	echo $CSQ1
fi



#################### NETWORK REGISTRATION MODE

if [[ ${OUTPUT} -eq 0 ]] 
then 
	echo -en "Network Registration Mode          : "
else
	echo -en "REGMODE="
fi

chat -Vs TIMEOUT 10 ECHO OFF "" "AT+COPS?" "OK" >/dev/modemAT </dev/modemAT 2>/tmp/log

REGEX='\+COPS:.([0-9]*),([0-9]*),"(.*)",([0-9]*)'
RESPONSE=$(</tmp/log)

COPS1=""
COPS2=""
COPS3=""
COPS4=""

if [[ $RESPONSE =~ $REGEX ]]
then
        COPS1="${BASH_REMATCH[1]}"
        COPS2="${BASH_REMATCH[2]}"
        COPS3="${BASH_REMATCH[3]}"
        COPS4="${BASH_REMATCH[4]}"
fi

if [[ $COPS1 -eq 0 ]] ; then
	if [[ ${OUTPUT} -eq 0 ]] ; then 	
		echo  "Automatic network selection"
	else
		echo "AUTOMATIC"
	fi
elif [[ $COPS1 -eq 1 ]]; then
	if [[ ${OUTPUT} -eq 0 ]] ; then 	
		echo  "Manual network selection"
	else	
		echo "MANUAL"
	fi
elif [[ $COPS1 -eq 2 ]]; then
	if [[ ${OUTPUT} -eq 0 ]] ; then 	
		echo "Deregister from network"
	else	
		echo "DE-REGISTERED"
	fi
elif [[ $COPS1 -eq 3 ]]; then
	if [[ ${OUTPUT} -eq 0 ]] ; then 	
		echo "Set, (no registration/deregistration)"
	else
		echo "SET"
	fi
elif [[ $COPS1 -eq 4 ]]; then
	if [[ ${OUTPUT} -eq 0 ]] ; then 	
		echo print "Manual selection with automatic fall back"
	else
		echo "MANUAL/AUTO"
	fi
fi


if (( $COPS1 >= 0 )) || (( $COPS1 <= 4 ))
then
		if [[ ${OUTPUT} -eq 0 ]] 
		then 
			echo "Network ID                         : ${COPS3}"
		else
			echo "NETWORKID='${COPS3}'"
		fi
else
		if [[ ${OUTPUT} -eq 0 ]] 
		then 
			echo "Network ID                         : ** Information Not Available"
		else
			echo "NETWORKID=NOTAVAILABLE"
		fi
fi

#################### NETWORK REGISTRATION STATE

if [[ ${OUTPUT} -eq 0 ]] 
then 
	echo -en "Registration state                 : ";
else
	echo -en "REGSTATE="
fi

chat -Vs TIMEOUT 10 ECHO OFF "" "AT+CREG?" "OK" >/dev/modemAT </dev/modemAT 2>/tmp/log

REGEX='\+CREG: ([0-9]*),([0-9]*)'
RESPONSE=$(</tmp/log)

CREG1=""
CREG2=""

if [[ $RESPONSE =~ $REGEX ]]
then
        CREG1="${BASH_REMATCH[1]}"
        CREG2="${BASH_REMATCH[2]}"
fi

if [[ $CREG2 -eq 0 ]] ; then
	if [[ ${OUTPUT} -eq 0 ]] ; then 	
        echo "Not Registered, Not searching"
	else
		echo "NOT-REGISTERED"
	fi
elif [[ $CREG2 -eq 1 ]]; then
	if [[ ${OUTPUT} -eq 0 ]] ; then 	
        echo "Registered to home network"
	else
		echo "REGISTERED-HOME"
	fi
		
elif [[ $CREG2 -eq 2 ]]; then
	if [[ ${OUTPUT} -eq 0 ]] ; then 	
        echo "Not registered, searching for network"
	else
		echo "SEARCHING"
	fi
elif [[ $CREG2 -eq 3 ]]; then
	if [[ ${OUTPUT} -eq 0 ]] ; then 	
        echo "Registration denied"      
	else
		echo "DENIED"
	fi

elif [[ $CREG2 -eq 4 ]]; then
	if [[ ${OUTPUT} -eq 0 ]] ; then 	
		echo "Registered, roaming"
	else
		echo "REGISTERED-ROAMING"
	fi              
else
	if [[ ${OUTPUT} -eq 0 ]] ; then 	
        echo " ** Infomation Not Available **"
	else
		echo "UNKNOWN"
	fi              
fi


###################### MODEM SPECIFIC PARTS ########################

#################### REGISTRATION MODE



######## QUECTEL
if [[ $MODEM -eq 1 ]] ; then

        chat -Vs TIMEOUT 10 ECHO OFF "" "AT+QNWINFO" "OK" >/dev/modemAT </dev/modemAT 2>/tmp/log

        REGEX='\+QNWINFO: "(.+)","(.+)","(.+)",'
        RESPONSE=$(</tmp/log)

        MODE1=""
        MODE2=""
        MODE3=""
        if [[ $RESPONSE =~ $REGEX ]]
        then
                        MODE1="${BASH_REMATCH[1]}"
                        MODE2="${BASH_REMATCH[2]}"
                        MODE3="${BASH_REMATCH[3]}"
        fi

		if [[ ${OUTPUT} -eq 0 ]] ; then 	
			echo -e "Modem Operating Mode               : $MODE1"
			echo -e "Modem Operating Band               : $MODE3"
		else
			echo "MODEMMODE='${MODE1}'"
			echo "MODEMBAND='${MODE3}'"
		fi

######## SIMCOM
elif [[ $MODEM -eq 2 ]]; then


        chat -Vs TIMEOUT 10 ECHO OFF "" "AT+CNSMOD?" "OK" >/dev/modemAT </dev/modemAT 2>/tmp/log

        REGEX='\+CNSMOD: ([0-9]),([0-9])'
        RESPONSE=$(</tmp/log)

        MODE1=""
        MODE2=""
		MODE3=""
        if [[ $RESPONSE =~ $REGEX ]]
        then
                        MODE1="${BASH_REMATCH[1]}"
                        MODE2="${BASH_REMATCH[2]}"
        fi
		if [[ ${OUTPUT} -eq 0 ]] ; then 
			echo -en "Modem Operating Mode               : "
		else
			echo -en "MODEMMODE="
		fi
		
        if [[ $MODE2 -eq 0 ]]; then			
                MODE3="No Service"
        elif [[ $MODE2 -eq 1 ]]; then
				MODE3="GSM"
        elif [[ $MODE2 -eq 2 ]]; then
                MODE3="GPRS"
        elif [[ $MODE2 -eq 3 ]]; then
                MODE3="EDGE"
        elif [[ $MODE2 -eq 4 ]]; then
                MODE3="WCDMA"
        elif [[ $MODE2 -eq 5 ]]; then
                MODE3="HSDPA"
        elif [[ $MODE2 -eq 6 ]]; then
                MODE3="HSUPA"
        elif [[ $MODE2 -eq 7 ]]; then
                MODE3="HSPA"
        elif [[ $MODE2 -eq 8 ]]; then
                MODE3="LTE"
        elif [[ $MODE2 -eq 9 ]]; then
                MODE3="TDS-CDMA"
        elif [[ $MODE2 -eq 10 ]]; then
                MODE3="TDS-HSDPA"
        elif [[ $MODE2 -eq 11 ]]; then
                MODE3="TDS-HSUPA"
        elif [[ $MODE2 -eq 12 ]]; then
                MODE3="TDS-HSPA"
        elif [[ $MODE2 -eq 13 ]]; then
                MODE3="CDMA"
        elif [[ $MODE2 -eq 14 ]]; then
                MODE3="EVDO"
        elif [[ $MODE2 -eq 15 ]]; then
                MODE3="HYBRID1"
        elif [[ $MODE2 -eq 16 ]]; then
                MODE3="1XLTE"
        elif [[ $MODE2 -eq 23 ]]; then
                MODE3="eHRPD"
        elif [[ $MODE2 -eq 24 ]]; then
                MODE3="HYBRID2"
        else
                MODE3="NOT-AVAILABLE"
        fi

		echo $MODE3
		
######## SIERRA WIRELESS
elif [[ $MODEM -eq 3 ]] ; then

        chat -Vs TIMEOUT 10 ECHO OFF "" "AT*CNTI=0" "OK" >/dev/modemAT </dev/modemAT 2>/tmp/log

        REGEX='\*CNTI: ([0-9]+),([a-zA-Z]+)'
        RESPONSE=$(</tmp/log)

        MODE1=""        
        if [[ $RESPONSE =~ $REGEX ]]
        then
				MODE1="${BASH_REMATCH[2]}"
        fi

		if [[ ${OUTPUT} -eq 0 ]]; then 
			echo -e "Modem Operating Mode               : $MODE1"
		else
			echo -e "MODEMMODE=$MODE1"
		fi

fi


##################### Display Modem Model Info
if [[ ${OUTPUT} -eq 0 ]]
then 
	chat -Vs TIMEOUT 10 ECHO OFF "" "ATI5" "OK" >/dev/modemAT </dev/modemAT 2>/tmp/log

	echo -e "Modem Specification   : \n"
	cat /tmp/log | head -n -1 | tail -n +2 | grep -v '^[[:space:]]*$'
fi 
 