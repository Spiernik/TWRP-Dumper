@echo off
ECHO ADB Dumper 0.0.1 
ECHO Copyright by Stepan
ECHO.
ECHO.


ECHO Starte ADB-Server
ECHO.
.\ressources\adb.exe start-server
ECHO ADB-Geraete:
.\ressources\adb.exe devices -l
set /P id=Sicherungsname:
mkdir %id%

ECHO Metadaten werden erfasst
.\ressources\adb.exe shell getprop > .\%id%\prop.csv

ECHO ADB-Geraet erfasst
ECHO ADB-Device: > .\%id%\%id%_info.txt
.\ressources\adb.exe devices -l >> .\%id%\%id%_info.txt

ECHO Zeitpunkt der Sicherung erfasst
ECHO Zeitpunkt der Sicherung: > .\%id%\%id%_info.txt
time /t >> .\%id%\%id%_info.txt
date /t >> .\%id%\%id%_info.txt

ECHO Zeit Geraet erfasst
ECHO. >> .\%id%\%id%_info.txt
ECHO Shell-Zeitstempel: >> .\%id%\%id%_info.txt
.\ressources\adb.exe shell date >> .\%id%\%id%_info.txt

ECHO Hersteller Geraet erfasst
ECHO. >> .\%id%\%id%_info.txt
ECHO Hersteller: >> .\%id%\%id%_info.txt
findstr brand .\%id%\prop.csv >> .\%id%\%id%_info.txt
findstr brand .\%id%\prop.csv >> .\%id%\%id%_info.txt

ECHO Modellbezeichnung erfasst
ECHO. >> .\%id%\%id%_info.txt
ECHO Modell: >> .\%id%\%id%_info.txt
findstr product.name .\%id%\prop.csv >> .\%id%\%id%_info.txt
findstr product.model .\%id%\prop.csv >> .\%id%\%id%_info.txt

ECHO IMEI erfasst
ECHO. >> .\%id%\%id%_info.txt
ECHO IMEI: >> .\%id%\%id%_info.txt
findstr imei .\%id%\prop.csv >> .\%id%\%id%_info.txt
.\ressources\adb.exe shell service call iphonesubinfo 1 >> .\%id%\%id%_info.txt
.\ressources\adb.exe shell service call iphonesubinfo 3 >> .\%id%\%id%_info.txt

ECHO Android-Version erfasst
ECHO. >> .\%id%\%id%_info.txt
ECHO Android-Version: >> .\%id%\%id%_info.txt
findstr build.version.release .\%id%\prop.csv >> .\%id%\%id%_info.txt

ECHO Security-Patch erfasst
ECHO. >> .\%id%\%id%_info.txt
ECHO Security-Patch: >> .\%id%\%id%_info.txt
findstr version.security_patch .\%id%\prop.csv >> .\%id%\%id%_info.txt


del /f .\%id%\prop.csv

ECHO Sichere Geraetespeicher %id%
.\ressources\adb.exe pull /dev/block/mmcblk0 .\%id%\%id%_mmcblk0.stepan
.\ressources\adb.exe pull /dev/block/sda .\%id%\%id%_sda.stepan
.\ressources\adb.exe pull /dev/block/sdb .\%id%\%id%_sdb.stepan
.\ressources\adb.exe pull /dev/block/sdc .\%id%\%id%_sdc.stepan
.\ressources\adb.exe pull /dev/block/sdd .\%id%\%id%_sdd.stepan
.\ressources\adb.exe pull /dev/block/sde .\%id%\%id%_sde.stepan
.\ressources\adb.exe pull /dev/block/sdf .\%id%\%id%_sdf.stepan
pause