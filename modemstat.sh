#!/bin/bash
############################################################################
# ModemStat -- Version 2.0.2
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

chat -Vs TIMEOUT 1 ECHO OFF "" "ATI5" "OK" >/dev/modemAT </dev/modemAT 2>/tmp/log
REGEX_SIMCOM='.*SIMCOM.*'
REGEX_QUECTEL='.*Quectel.*'
REGEX_SIERRA='.*Sierra.*'
REGEX_NIMBELINK='.*DOB*'

RESPONSE=$(</tmp/log)

if [[ $RESPONSE =~ $REGEX_QUECTEL ]] ; then
        MODEM=1   # QUECTEL
        MODEMVENDOR="QUECTEL"
elif [[ $RESPONSE =~ $REGEX_SIMCOM ]] ; then
        MODEM=2   # SIMCOM/OTHER:
        MODEMVENDOR="SIMCOM"
elif [[ $RESPONSE =~ $REGEX_SIERRA ]] ; then
        MODEM=3   # SIERRA WIRELESS
        MODEMVENDOR="SIERRA-WIRELESS"
elif [[ $RESPONSE =~ $REGEX_NIMBELINK ]] ; then
        MODEM=4   # NIMBELINK
        MODEMVENDOR="NIMBELINK TELIT LE910C"		
else
        MODEM=0   # UNKNOWN
        MODEMVENDOR="UNKNOWN"
fi

#################### MODEM IMEI NUMBER

chat -Vs TIMEOUT 1 ECHO OFF "" "AT+GSN" "OK" >/dev/modemAT </dev/modemAT 2>/tmp/log

REGEX='^([0-9]+)$'
RESPONSE=`cat /tmp/log | head -n -1 | tail -n +2 | grep -v '^[[:space:]]*$'`

IMEI=""

if [[ $RESPONSE =~ $REGEX ]]
then
        IMEI="${BASH_REMATCH[1]}"
fi


#################### SIM NUMBER

# Doesn't work on Sierra Wireless Modems
if [[ $MODEM != 3 ]]
then
        chat -Vs TIMEOUT 1 ECHO OFF "" "AT+ICCID" "OK" >/dev/modemAT </dev/modemAT 2>/tmp/log

        REGEX='\+ICCID: ([0-9]+)'
        RESPONSE=$(</tmp/log)

        SIMID=""

        if [[ $RESPONSE =~ $REGEX ]]
        then
                SIMID="${BASH_REMATCH[1]}"
        fi        
fi

#################### SIM &  PIN CHECK



chat -Vs TIMEOUT 1 ECHO OFF "" "AT+CPIN?" "OK" >/dev/modemAT </dev/modemAT 2>/tmp/log

REGEX='\+CPIN:.([a-zA-Z]*)'
RESPONSE=$(</tmp/log)

CPIN=""

if [[ $RESPONSE =~ $REGEX ]]
then
        CPIN="${BASH_REMATCH[1]}"
fi

if [[ $CPIN == "READY"   ]]; then
        PINSTATUS="SIM unlocked and ready";
elif [[ $CPIN == "SIM PIN" ]]; then
        PINSTATUS="SIM PIN LOCKED - MUST DEACTIVATE BEFORE USE WITH SYSTEM";
elif [[ $CPIN == "SIM PUK" ]]; then
        PINSTATUS="SIM LOCKED BY NETWORK OPERATOR - MUST DEACTIVATE BEFORE USE WITH SYSTEM";
elif [[ $CPIN == "BLOCKED" ]]; then
        PINSTATUS="LOCKED BY NETWORK OPERATOR - MUST DEACTIVATE BEFORE USE WITH SYSTEM";
elif [[ $CPIN == "PH-NET PIN" ]]; then
        PINSTATUS="MODEM LOCKED BY NETWORK OPERATOR - MUST DEACTIVATE BEFORE USE WITH SYSTEM";
else
        PINSTATUS=" ** Infomation Not Available **"
        CPIN="NOTAVAILABLE"
fi

#################### SIGNAL QUALITY



chat -Vs TIMEOUT 1 ECHO OFF "" "AT+CSQ" "OK" >/dev/modemAT </dev/modemAT 2>/tmp/log

REGEX='\CSQ: ([0-9]*),([0-9]*)'
RESPONSE=$(</tmp/log)

CSQ1=""
CSQ2=""


if [[ $RESPONSE =~ $REGEX ]]
then
        CSQ1="${BASH_REMATCH[1]}"
        CSQ2="${BASH_REMATCH[2]}"
fi


#################### NETWORK REGISTRATION MODE


chat -Vs TIMEOUT 1 ECHO OFF "" "AT+COPS?" "OK" >/dev/modemAT </dev/modemAT 2>/tmp/log

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
                REGMODE="Automatic network selection"
        else
                REGMODE="AUTOMATIC"
        fi
elif [[ $COPS1 -eq 1 ]]; then
        if [[ ${OUTPUT} -eq 0 ]]
        then
                REGMODE="Manual network selection"
        else
                REGMODE="MANUAL"
        fi
elif [[ $COPS1 -eq 2 ]]; then
        if [[ ${OUTPUT} -eq 0 ]]
        then
                REGMODE="Deregister from network"
        else
                REGMODE="DE-REGISTERED"
        fi
elif [[ $COPS1 -eq 3 ]]; then
        if [[ ${OUTPUT} -eq 0 ]]
        then
                REGMODE="Set, (no registration/deregistration)"
        else
                REGMODE="SET"
        fi
elif [[ $COPS1 -eq 4 ]]; then
        if [[ ${OUTPUT} -eq 0 ]]
        then
                REGMODE="Manual selection with automatic fall back"
        else
                REGMODE="MANUAL/AUTO"
        fi
fi


if [ ! -z "$COPS1" ]
then
        if  (( $COPS1 >= 0 )) || (( $COPS1 <= 4 ))
        then
                if [[ ${OUTPUT} -eq 0 ]]
                then
                        NETWORKID="${COPS3}"
                else
                        NETWORKID="'${COPS3}'"
		fi
        fi
else
        if [[ ${OUTPUT} -eq 0 ]]
        then
                NETWORKID="** Information Not Available **"
        else
                NETWORKID="NOTAVAILABLE"
        fi
fi



#################### NETWORK REGISTRATION STATE


chat -Vs TIMEOUT 1 ECHO OFF "" "AT+CREG?" "OK" >/dev/modemAT </dev/modemAT 2>/tmp/log

REGEX='\+CREG: ([0-9]*),([0-9]*)'
RESPONSE=$(</tmp/log)

CREG1=""
CREG2=""

if [[ $RESPONSE =~ $REGEX ]]
then
        CREG1="${BASH_REMATCH[1]}"
        CREG2="${BASH_REMATCH[2]}"

        if [[ $CREG2 -eq 0 ]] ; then
                if [[ ${OUTPUT} -eq 0 ]] ; then
                        REGSTATE="Not Registered, Not searching"
                else
                        REGSTATE="NOT-REGISTERED"
                fi
        elif [[ $CREG2 -eq 1 ]]; then
                if [[ ${OUTPUT} -eq 0 ]] ; then
                        REGSTATE="Registered to home network"
                else
                        REGSTATE="REGISTERED-HOME"
                fi

        elif [[ $CREG2 -eq 2 ]]; then
                if [[ ${OUTPUT} -eq 0 ]] ; then
                        REGSTATE="Not registered, searching for network"
                else
                        REGSTATE="SEARCHING"
                fi
        elif [[ $CREG2 -eq 3 ]]; then
                if [[ ${OUTPUT} -eq 0 ]] ; then
                        REGSTATE="Registration denied"
                else
                        REGSTATE="DENIED"
                fi

        elif [[ $CREG2 -eq 4 ]]; then
                if [[ ${OUTPUT} -eq 0 ]] ; then
                        REGSTATE="Registered, roaming"
                else
                        REGSTATE="REGISTERED-ROAMING"
                fi
        else
                if [[ ${OUTPUT} -eq 0 ]] ; then
                        REGSTATE=" ** Infomation Not Available **"
                else
                        REGSTATE="UNKNOWN"
                fi
        fi
fi

###################### MODEM SPECIFIC PARTS ########################

#################### REGISTRATION MODE



######## QUECTEL
if [[ $MODEM -eq 1 ]] ; then

        chat -Vs TIMEOUT 1 ECHO OFF "" "AT+QNWINFO" "OK" >/dev/modemAT </dev/modemAT 2>/tmp/log

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

######## SIMCOM
elif [[ $MODEM -eq 2 ]]; then


        chat -Vs TIMEOUT 1 ECHO OFF "" "AT+CNSMOD?" "OK" >/dev/modemAT </dev/modemAT 2>/tmp/log

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

######## SIERRA WIRELESS
elif [[ $MODEM -eq 3 ]] ; then

        chat -Vs TIMEOUT 1 ECHO OFF "" "AT*CNTI=0" "OK" >/dev/modemAT </dev/modemAT 2>/tmp/log

        REGEX='\*CNTI: ([0-9]+),([a-zA-Z]+)'
        RESPONSE=$(</tmp/log)

        MODE1=""

        if [[ $RESPONSE =~ $REGEX ]]
        then
                MODE1="${BASH_REMATCH[2]}"
        fi
fi


if [[ ${OUTPUT} -eq 0 ]]
then
        echo
        echo -e "Modem Vendor                       : $MODEMVENDOR"
        echo -e "Modem IMEI Number                  : $IMEI"
        echo -e "SIM ID Number                      : $SIMID"
        echo -e "SIM Status                         : $PINSTATUS"
        echo -e "Signal Quality                     : ${CSQ1}/32"
        echo -e "Network Registration Mode          : ${REGMODE}"
        echo -e "Network ID                         : ${NETWORKID}"
        echo -e "Registration state                 : ${REGSTATE}"
        if [[ $MODEM -eq 1 ]] ; then
                echo -e "Modem Operating Mode               : $MODE1"
                echo -e "Modem Operating Band               : $MODE3"
        elif [[ $MODEM -eq 2 ]] ; then
                echo -e "Modem Operating Band               : $MODE3"
        elif [[ $MODEM -eq 3 ]] ; then
                echo -e "Modem Operating Mode               : $MODE1"
        fi
else
        echo -e "MODEMVENDOR=$MODEMVENDOR"
        echo -e "IMEI=$IMEI"
        echo -e "SIM=$SIMID"
        echo -e "SIMSTATUS=$CPIN"
        echo -e "SIGNAL=$CSQ1"
        echo -e "REGMODE=$REGMODE"
        echo -e "NETWORKID=$NETWORKID"
        echo -e "REGSTATE=$REGSTATE"
        if [[ $MODEM -eq 1 ]] ; then
                echo -e "MODEMMODE='${MODE1}'"
                echo -e "MODEMBAND='${MODE3}'"
        elif [[ $MODEM -eq 2 ]] ; then
                echo -e "MODEMBAND='${MODE3}'"
        elif [[ $MODEM -eq 3 ]] ; then
                echo -e "MODEMMODE='${MODE1}'"
        fi

fi

##################### Display Modem Model Info
if [[ ${OUTPUT} -eq 0 ]]
then
	if [[ $MODEM != 4 ]]
	then
        	chat -Vs TIMEOUT 1 ECHO OFF "" "ATI5" "OK" >/dev/modemAT </dev/modemAT 2>/tmp/log

        	echo -e "Modem Specification   : \n"
        	cat /tmp/log | head -n -1 | tail -n +2 | grep -v '^[[:space:]]*$'
	fi
	echo
fi
