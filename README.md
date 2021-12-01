# modemstat
ModemStatus Utility

Gives modem status information, autodetects between Sierra Wireless/Quectel/Simcom modems

```
root@raspberrypi:~# ./modemstat2.sh
Modem Vendor                       : QUECTEL
Modem IMEI Number                  : 234159548225248
SIM ID Number                      : 89441000304200027130
SIM Status                         : SIM unlocked and ready
Signal Quality                     : 14/32
Network Registration Mode          : Automatic network selection
Network ID                         : vodafone UK
Registration state                 : Registered to home network
Modem Operating Mode               : FDD LTE
Modem Operating Band               : LTE BAND 1
Modem Specification   :

Quectel
EC25
Revision: EC25EFAR06A11M4G
```


Running with -q dumps as bash variables

```
root@raspberrypi:~# ./modemstat2.sh -q
MODEMVENDOR=QUECTEL
IMEI=234159548225248
SIM=89441000304200027130
SIMSTATUS='READY'
SIGNAL=14
REGMODE=AUTOMATIC
NETWORKID='vodafone UK'
REGSTATE=REGISTERED-HOME
MODEMMODE='FDD LTE'
MODEMBAND='LTE BAND 1'
````

This can be integrated into a bash script as per the example below

```
root@raspberrypi:~# ./test.sh
Sim Number  = [89441000304200027130]
Sim Status  = [READY]
Reg State   = [REGISTERED-HOME]
Modem Mode  = [FDD LTE]

root@raspberrypi:~# cat test.sh
source <(./modemstat2.sh -q)
echo "Sim Number  = [$SIM]"
echo "Sim Status  = [$SIMSTATUS]"
echo "Reg State   = [$REGSTATE]"
echo "Modem Mode  = [$MODEMMODE]"
```

See source and PDF files for more details 

