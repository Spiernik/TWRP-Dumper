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
ECHO [1;4mBitte Sicherungsname eingeben.[0m
ECHO.
set /P id=Sicherungsname:

::Datum erfassen
set d=%date%
set SORTDATE=%d:~-4%-%d:~3,2%-%d:~0,2%

::Zeit Erfassen
set t=%time%
set SORTTIME=%t:~0,2%%t:~3,2%%t:~6,2%
if "%SORTTIME:~0,1%"==" " set SORTTIME=0%SORTTIME:~1,6%

::Erstelle den Ordner
set idDir=%id%-%SORTDATE%-%SORTTIME%
MKDIR %idDir%
ECHO.

::Abfrage ob Metadaten erfasst werden sollen
set /P askMeta="Metadaten erfassen? (y/n) "
ECHO.
IF %askMeta% == y GOTO META
	IF %askMeta% == z GOTO META
	GOTO DUMP

:META
::Erfasse Metadaten
.\ressources\adb.exe shell getprop > .\%idDir%\prop.csv

ECHO [1;4mErfasse Metadaten zur Sicherung[0m

ECHO [36mADB-Geraet erfasst[0m
ECHO ADB-Device: > .\%idDir%\%id%_info.txt
.\ressources\adb.exe devices -l >> .\%idDir%\%id%_info.txt

ECHO [36mZeitpunkt der Sicherung erfasst[0m
ECHO Zeitpunkt der Sicherung: > .\%idDir%\%id%_info.txt
ECHO %time% >> .\%idDir%\%id%_info.txt
ECHO %date% >> .\%idDir%\%id%_info.txt

ECHO [36mZeit Geraet erfasst[0m
ECHO. >> .\%idDir%\%id%_info.txt
ECHO Shell-Zeitstempel: >> .\%idDir%\%id%_info.txt
.\ressources\adb.exe shell date >> .\%idDir%\%id%_info.txt

ECHO [36mHersteller Geraet erfasst[0m
ECHO. >> .\%idDir%\%id%_info.txt
ECHO Hersteller: >> .\%idDir%\%id%_info.txt
findstr brand .\%idDir%\prop.csv >> .\%idDir%\%id%_info.txt
findstr brand .\%idDir%\prop.csv >> .\%idDir%\%id%_info.txt

ECHO [36mModellbezeichnung erfasst[0m
ECHO. >> .\%idDir%\%id%_info.txt
ECHO Modell: >> .\%idDir%\%id%_info.txt
findstr product.manufacturer .\%idDir%\prop.csv >> .\%idDir%\%id%_info.txt
findstr product.name .\%idDir%\prop.csv >> .\%idDir%\%id%_info.txt
findstr product.model .\%idDir%\prop.csv >> .\%idDir%\%id%_info.txt

ECHO [36mIMEI erfasst[0m
ECHO. >> .\%idDir%\%id%_info.txt
ECHO IMEI: >> .\%idDir%\%id%_info.txt
findstr imei .\%idDir%\prop.csv >> .\%idDir%\%id%_info.txt
.\ressources\adb.exe shell service call iphonesubinfo 1 >> .\%idDir%\%id%_info.txt
.\ressources\adb.exe shell service call iphonesubinfo 3 >> .\%idDir%\%id%_info.txt

ECHO [36mAndroidDir-Version erfasst[0m
ECHO. >> .\%idDir%\%id%_info.txt
ECHO AndroidDir-Version: >> .\%idDir%\%id%_info.txt
findstr build.version.release .\%idDir%\prop.csv >> .\%idDir%\%id%_info.txt

ECHO [36mSecurity-Patch erfasst[0m
ECHO. >> .\%idDir%\%id%_info.txt
ECHO Security-Patch: >> .\%idDir%\%id%_info.txt
findstr version.security_patch .\%idDir%\prop.csv >> .\%idDir%\%id%_info.txt

ECHO [36mSeriennummer erfasst[0m
ECHO. >> .\%idDir%\%id%_info.txt
ECHO Seriennummer: >> .\%idDir%\%id%_info.txt
.\ressources\adb.exe get-serialno >> .\%idDir%\%id%_info.txt

ECHO [36mFilesystem erfasst[0m
ECHO. >> .\%idDir%\%id%_info.txt
ECHO Filesystem: >> .\%idDir%\%id%_info.txt
.\ressources\adb.exe shell df >> .\%idDir%\%id%_info.txt
ECHO.
ECHO.

::Lösche die Temp Datei
del /f .\%idDir%\prop.csv

:DUMP
ECHO [101;93mSichere Geraetespeicher[0m
ECHO.
::Versuche die verschiedenen Speicher zu kopieren.
.\ressources\adb.exe pull /dev/block/mmcblk0 .\%idDir%\%id%_mmcblk0.stepan 2>NUL
IF %ERRORLEVEL% NEQ 0 (
	ECHO mmcblk nicht gefunden. Probiere stattdessen SDA
	ECHO.
	goto SDA
) ELSE (
	ECHO mmcblk erfolgreich kopiert
	ECHO.
	goto HashMmc
)

:HashMmc
::Berechne Hashwerte
ECHO Hashwert wird berechnet
ECHO MD5: >> .\%idDir%\%id%_info.txt
CertUtil -hashfile .\%idDir%\%id%_mmcblk0.stepan MD5 | find /i /v "md5" | find /i /v "certutil" >> .\%idDir%\%id%_info.txt
ECHO SHA256: >> .\%idDir%\%id%_info.txt
CertUtil -hashfile .\%idDir%\%id%_mmcblk0.stepan SHA256 | find /i /v "sha256" | find /i /v "certutil" >> .\%idDir%\%id%_info.txt
ECHO Hashwert erfolgreich berechnet
GOTO END

:SDA
.\ressources\adb.exe pull /dev/block/sdc .\%idDir%\%id%_sda.stepan
ECHO Hashwert wird berechnet
ECHO MD5: >> .\%idDir%\%id%_info.txt
CertUtil -hashfile .\%idDir%\%id%_sda.stepan MD5 | find /i /v "md5" | find /i /v "certutil" >> .\%idDir%\%id%_info.txt
ECHO SHA256: >> .\%idDir%\%id%_info.txt
CertUtil -hashfile .\%idDir%\%id%_sda.stepan SHA256 | find /i /v "sha256" | find /i /v "certutil" >> .\%idDir%\%id%_info.txt
ECHO Hashwert erfolgreich berechnet
ECHO.
ECHO Kopiere sonstige Partitionen
.\ressources\adb.exe pull /dev/block/sdb .\%idDir%\%id%_sdb.stepan
.\ressources\adb.exe pull /dev/block/sdc .\%idDir%\%id%_sdc.stepan
.\ressources\adb.exe pull /dev/block/sdd .\%idDir%\%id%_sdd.stepan
.\ressources\adb.exe pull /dev/block/sde .\%idDir%\%id%_sde.stepan
.\ressources\adb.exe pull /dev/block/sdf .\%idDir%\%id%_sdf.stepan
ECHO Interner Speicher erfolgreich kopiert

:END
::Kille ADB Server
.\ressources\adb.exe kill-server
ECHO TWRP-Dumper abgeschlossen.
pause >NUL