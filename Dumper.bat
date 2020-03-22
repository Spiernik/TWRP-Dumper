@echo off
cls
ECHO ADB Dumper 0.0.1 
ECHO Copyright by Stepan

echo [101;93m
:: Displays Ascii art
type .\ressources\art
echo [0m

::Starte den ADB Server
ECHO [1;4mStarte ADB-Server[0m
ECHO.
.\ressources\adb.exe kill-server
::Sleep um auf adb zu warten
@ping -n 2 localhost> nul
.\ressources\adb.exe start-server
ECHO.

::ADB Geräte ausgeben
ECHO [1;4mADB-Geraete:[0m
ECHO.
.\ressources\adb.exe devices -l


ECHO Modellbezeichnung:
.\ressources\adb.exe shell getprop > .\temp
findstr product.model .\temp
del /f .\temp
ECHO.

::Name eingeben
:: ToDo: Abfragen ob Ordner bereits existiert
ECHO [1;4mBitte Sicherungsname eingeben.[0m
ECHO.
set /P id=Sicherungsname:
mkdir %id%
ECHO.

::Abfrage ob Metadaten erfasst werden sollen
set /P askMeta="Metadaten erfassen? (y/n) "
ECHO.
IF %askMeta% == y GOTO META
	IF %askMeta% == z GOTO META
	GOTO DUMP

:META
::Erfasse Metadaten
.\ressources\adb.exe shell getprop > .\%id%\prop.csv

ECHO [1;4mErfasse Metadaten zur Sicherung[0m

ECHO [36mADB-Geraet erfasst[0m
ECHO ADB-Device: > .\%id%\%id%_info.txt
.\ressources\adb.exe devices -l >> .\%id%\%id%_info.txt

ECHO [36mZeitpunkt der Sicherung erfasst[0m
ECHO Zeitpunkt der Sicherung: > .\%id%\%id%_info.txt
time /t >> .\%id%\%id%_info.txt
date /t >> .\%id%\%id%_info.txt

ECHO [36mZeit Geraet erfasst[0m
ECHO. >> .\%id%\%id%_info.txt
ECHO Shell-Zeitstempel: >> .\%id%\%id%_info.txt
.\ressources\adb.exe shell date >> .\%id%\%id%_info.txt

ECHO [36mHersteller Geraet erfasst[0m
ECHO. >> .\%id%\%id%_info.txt
ECHO Hersteller: >> .\%id%\%id%_info.txt
findstr brand .\%id%\prop.csv >> .\%id%\%id%_info.txt
findstr brand .\%id%\prop.csv >> .\%id%\%id%_info.txt

ECHO [36mModellbezeichnung erfasst[0m
ECHO. >> .\%id%\%id%_info.txt
ECHO Modell: >> .\%id%\%id%_info.txt
findstr product.manufacturer .\%id%\prop.csv >> .\%id%\%id%_info.txt
findstr product.name .\%id%\prop.csv >> .\%id%\%id%_info.txt
findstr product.model .\%id%\prop.csv >> .\%id%\%id%_info.txt

ECHO [36mIMEI erfasst[0m
ECHO. >> .\%id%\%id%_info.txt
ECHO IMEI: >> .\%id%\%id%_info.txt
findstr imei .\%id%\prop.csv >> .\%id%\%id%_info.txt
.\ressources\adb.exe shell service call iphonesubinfo 1 >> .\%id%\%id%_info.txt
.\ressources\adb.exe shell service call iphonesubinfo 3 >> .\%id%\%id%_info.txt

ECHO [36mAndroid-Version erfasst[0m
ECHO. >> .\%id%\%id%_info.txt
ECHO Android-Version: >> .\%id%\%id%_info.txt
findstr build.version.release .\%id%\prop.csv >> .\%id%\%id%_info.txt

ECHO [36mSecurity-Patch erfasst[0m
ECHO. >> .\%id%\%id%_info.txt
ECHO Security-Patch: >> .\%id%\%id%_info.txt
findstr version.security_patch .\%id%\prop.csv >> .\%id%\%id%_info.txt

ECHO [36mSeriennummer erfasst[0m
ECHO. >> .\%id%\%id%_info.txt
ECHO Seriennummer: >> .\%id%\%id%_info.txt
.\ressources\adb.exe get-serialno >> .\%id%\%id%_info.txt

ECHO [36mFilesystem erfasst[0m
ECHO. >> .\%id%\%id%_info.txt
ECHO Filesystem: >> .\%id%\%id%_info.txt
.\ressources\adb.exe shell df >> .\%id%\%id%_info.txt
ECHO.
ECHO.


::Lösche die Temp Datei
del /f .\%id%\prop.csv

:DUMP
ECHO [101;93mSichere Geraetespeicher[0m
ECHO.
::Versuche die verschiedenen Speicher zu kopieren. ToDo: Try/Catch einfügen
.\ressources\adb.exe pull /dev/block/mmcblk0 .\%id%\%id%_mmcblk0.stepan
.\ressources\adb.exe pull /dev/block/sda .\%id%\%id%_sda.stepan
.\ressources\adb.exe pull /dev/block/sdb .\%id%\%id%_sdb.stepan
.\ressources\adb.exe pull /dev/block/sdc .\%id%\%id%_sdc.stepan
.\ressources\adb.exe pull /dev/block/sdd .\%id%\%id%_sdd.stepan
.\ressources\adb.exe pull /dev/block/sde .\%id%\%id%_sde.stepan
.\ressources\adb.exe pull /dev/block/sdf .\%id%\%id%_sdf.stepan

::Kille ADB Server
.\ressources\adb.exe kill-server

::Berechne Hashwerte
ECHO MD5: >> .\%id%\%id%_info.txt
CertUtil -hashfile .\%id%\%id%_mmcblk0.stepan MD5 | find /i /v "md5" | find /i /v "certutil"

ECHO SHA256: >> .\%id%\%id%_info.txt
CertUtil -hashfile .\%id%\%id%_mmcblk0.stepan SHA256 | find /i /v "sha256" | find /i /v "certutil"

pause