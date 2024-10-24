@echo off
cls
setlocal EnableDelayedExpansion
(set \n=^
%=empty line=%
)
ECHO ADB Dumper 0.0.1.2
ECHO Copyright, Copyleft and Copymiddle by Stepan
::Nächste Version auch Copyup und Copydown unterstützen

echo [101;93m
:: Displays Ascii art
type .\ressources\art
echo [0m

:START
::Starte den ADB Server
ECHO [1;4mStarte ADB-Server[0m
ECHO.
.\ressources\adb.exe kill-server
::Sleep um auf adb zu warten
@ping -n 2 localhost> nul
.\ressources\adb.exe start-server
ECHO.

::Kontrollieren ob Gerät in recovery-modus über adb erkannt wurde
ECHO [1;4mADB-Geraete:[0m
ECHO.
.\ressources\adb.exe devices | find "recovery" >nul
if errorlevel 1 (
	ECHO [91mKein Geraet im Recovery-Modus gefunden.[0m
	ECHO Warte 5 Sekunden und starte dann neu.
	@ping -n 5 localhost> nul
	GOTO START
) else (
	ECHO [92mGeraet im Recovery-Modus gefunden.[0m
	ECHO.
	.\ressources\adb.exe devices -l
)

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

::Abfrage ob Komprimiert werden sollen
set /P askCompress="Sicherung komprimieren(.e01)? (y/n) "
ECHO.

::Abfrage ob Hash berechnet werden sollen
set /P askHash="Sicherung hashen?(SHA256 und md5; VORSICHT dauert lange!)? (y/n) "
ECHO.

::Erstelle den Ordner
set idDir=%id%-%SORTDATE%-%SORTTIME%
MKDIR %idDir%
ECHO.

::Variablen für die UFD-Datei
set DeviceInfo=[DeviceInfo]
set Dumps=[Dumps]
set General=[General]
set ExtractionStatus=[ExtractionStatus]
set SHA256=[SHA256]
set Hash=[Hash]
set ImageName=0

::Erfasse Metadaten
.\ressources\adb.exe shell getprop > .\%idDir%\prop.csv

ECHO [1;4mErfasse Metadaten zur Sicherung[0m

::ADBGeraete erfassen
ECHO ADB-Device: > .\%idDir%\%id%_info.txt
.\ressources\adb.exe devices -l >> .\%idDir%\%id%_info.txt

::Zeitpunkt der Sicherung erfassen
ECHO Zeitpunkt der Sicherung: >> .\%idDir%\%id%_info.txt
ECHO %time% >> .\%idDir%\%id%_info.txt
ECHO %date% >> .\%idDir%\%id%_info.txt
set General=!General!!\n!Date=%date% %time%

::Zeit des Geraets erfassen
ECHO. >> .\%idDir%\%id%_info.txt
ECHO Shell-Zeitstempel: >> .\%idDir%\%id%_info.txt
.\ressources\adb.exe shell date >> .\%idDir%\%id%_info.txt

::Hersteller des Geraets erfassen
ECHO. >> .\%idDir%\%id%_info.txt
ECHO Hersteller: >> .\%idDir%\%id%_info.txt
findstr brand .\%idDir%\prop.csv >> .\%idDir%\%id%_info.txt

::Modellbezeichnung des Geraets erfassen
ECHO. >> .\%idDir%\%id%_info.txt
ECHO Modell: >> .\%idDir%\%id%_info.txt
findstr product.manufacturer .\%idDir%\prop.csv >> .\%idDir%\%id%_info.txt
findstr product.name .\%idDir%\prop.csv >> .\%idDir%\%id%_info.txt
findstr product.model .\%idDir%\prop.csv >> .\%idDir%\%id%_info.txt

::DeviceModel in DeviceInfoVariable
FINDSTR product.model .\%idDir%\prop.csv > tmp2.txt
SET /p tmp2=<tmp2.txt
set DeviceInfo=!DeviceInfo!!\n!Model=%tmp2%

::DeviceHersteller in DeviceInfoVariable
FINDSTR product.manufacturer .\%idDir%\prop.csv > tmp2.txt
SET /p tmp2=<tmp2.txt
set DeviceInfo=!DeviceInfo!!\n!Vendor=%tmp2%

::IMEI erfassen
ECHO. >> .\%idDir%\%id%_info.txt
ECHO IMEI: >> .\%idDir%\%id%_info.txt
findstr imei .\%idDir%\prop.csv >> .\%idDir%\%id%_info.txt
.\ressources\adb.exe shell service call iphonesubinfo 1 >> .\%idDir%\%id%_info.txt
.\ressources\adb.exe shell service call iphonesubinfo 3 >> .\%idDir%\%id%_info.txt

::Android-Version erfassen
ECHO. >> .\%idDir%\%id%_info.txt
ECHO AndroidOS-Version: >> .\%idDir%\%id%_info.txt
findstr build.version.release .\%idDir%\prop.csv >> .\%idDir%\%id%_info.txt

::AndroidOS-Version in DeviceInfoVariable
FINDSTR build.version.release .\%idDir%\prop.csv > tmp2.txt
SET /p tmp2=<tmp2.txt
set DeviceInfo=!DeviceInfo!!\n!OS=%tmp2%

::SecurityPatchLevel erfassen
ECHO. >> .\%idDir%\%id%_info.txt
ECHO Security-Patch: >> .\%idDir%\%id%_info.txt
findstr version.security_patch .\%idDir%\prop.csv >> .\%idDir%\%id%_info.txt

::SecurityPatchLevel in DeviceInfoVariable
FINDSTR version.security_patch .\%idDir%\prop.csv > tmp2.txt
SET /p tmp2=<tmp2.txt
set DeviceInfo=!DeviceInfo!!\n!SecurityPatchLevel=%tmp2%

::Seriennummer erfassen
ECHO. >> .\%idDir%\%id%_info.txt
ECHO Seriennummer: >> .\%idDir%\%id%_info.txt
.\ressources\adb.exe get-serialno >> .\%idDir%\%id%_info.txt

::Filesystem erfassen
ECHO. >> .\%idDir%\%id%_info.txt
ECHO Filesystem: >> .\%idDir%\%id%_info.txt
.\ressources\adb.exe shell df >> .\%idDir%\%id%_info.txt
ECHO.
ECHO.

:DUMP
::Sichert den Speicher
ECHO [101;93mSichere Geraetespeicher[0m
ECHO.

::Versuche die verschiedenen Speicher zu kopieren. Hier: mmcblk
.\ressources\adb.exe pull /dev/block/mmcblk0 .\%idDir%\%id%_mmcblk0.stepan 2>NUL

IF %ERRORLEVEL% NEQ 0 (
	ECHO.
	ECHO mmcblk nicht gefunden. 
	ECHO Probiere stattdessen nandX.
	ECHO.
	goto NANDX
) ELSE (
	ECHO mmcblk erfolgreich kopiert
	ECHO.
	set General=!General!!\n!EndTime=%date% %time%
	set ExtractionStatus=%ExtractionStatus%!\n!ExtractionStatus=Success
	IF %askCompress% == y (SET ImageName=%id%_mmcblk0.e01) ELSE SET ImageName=%id%_mmcblk0.stepan
	IF %askCompress% == y (set Dumps=%Dumps%!\n!Image=%id%_mmcblk0.e01) else set Dumps=%Dumps%!\n!Image=%id%_mmcblk0.stepan
	IF %askCompress% == y .\ressources\ftkimager\ftkimager.exe .\%idDir%\%id%_mmcblk0.stepan .\%idDir%\%id%_mmcblk0 --e01 --compress 9	
	IF %askHash% == y goto HashMmc	
	GOTO END
)

:HashMmc
::Berechne Hashwerte für mmcblk
ECHO Hashwert wird berechnet
ECHO MD5: >> .\%idDir%\%id%_info.txt
set tmp=CertUtil -hashfile .\%idDir%\%id%_mmcblk0.stepan MD5 | find /i /v "md5" | find /i /v "certutil"
%tmp% >> .\%idDir%\%id%_info.txt
set Hash=%Hash%!\n!%tmp%
ECHO MD5=%tmp%
ECHO SHA256: >> .\%idDir%\%id%_info.txt
set tmp=CertUtil -hashfile .\%idDir%\%id%_mmcblk0.stepan SHA256 | find /i /v "sha256" | find /i /v "certutil"
%tmp% >> .\%idDir%\%id%_info.txt
set SHA256=%SHA256%!\n!%tmp%
ECHO SHA256=%tmp%
ECHO Hashwert erfolgreich berechnet
GOTO END

:HashSDA
::Berechne Hashwerte für SDA
ECHO Hashwert wird berechnet
ECHO MD5: >> .\%idDir%\%id%_info.txt
set tmp=CertUtil -hashfile .\%idDir%\%id%_sda.stepan MD5 | find /i /v "md5" | find /i /v "certutil"
%tmp% >> .\%idDir%\%id%_info.txt
set Hash=%Hash%!\n!%tmp%
ECHO MD5=%tmp%
ECHO SHA256: >> .\%idDir%\%id%_info.txt
set tmp=CertUtil -hashfile .\%idDir%\%id%_sda.stepan SHA256 | find /i /v "sha256" | find /i /v "certutil"
%tmp% >> .\%idDir%\%id%_info.txt
set SHA256=%SHA256%!\n!%tmp%
ECHO SHA256=%tmp%

ECHO Hashwert erfolgreich berechnet
GOTO END

:SDA
.\ressources\adb.exe pull /dev/block/sda .\%idDir%\%id%_sda.stepan 2>NUL
	IF %ERRORLEVEL% NEQ 0 (
		ECHO.
		ECHO interner Speicher nicht gefunden.
		ECHO.
		goto END
	)
IF %askCompress% == y (set Dumps=%Dumps%!\n!Image=%id%_sda.e01) else set Dumps=%Dumps%!\n!Image=%id%_sda.stepan
IF %askCompress% == y .\ressources\ftkimager\ftkimager.exe .\%idDir%\%id%_sda.stepan .\%idDir%\%id%_sda --e01 --compress 9
SET ImageName=%id%_mmcblk0.sda
ECHO.
ECHO Kopiere sonstige Partitionen
.\ressources\adb.exe pull /dev/block/sdb .\%idDir%\%id%_sdb.stepan 2>NUL
	IF %ERRORLEVEL% NEQ 0 (
		ECHO.
		ECHO SDB nicht gefunden.
		ECHO.
		goto NANDXEND
	)
IF %askCompress% == y (set Dumps=%Dumps%!\n!Image=%id%_sdb.e01) else set Dumps=%Dumps%!\n!Image=%id%_sdb.stepan
IF %askCompress% == y .\ressources\ftkimager\ftkimager.exe .\%idDir%\%id%_sdb.stepan .\%idDir%\%id%_sdb --e01 --compress 9
.\ressources\adb.exe pull /dev/block/sdc .\%idDir%\%id%_sdc.stepan 2>NUL
	IF %ERRORLEVEL% NEQ 0 (
		ECHO.
		ECHO SDC nicht gefunden.
		ECHO.
		goto NANDXEND
	)
IF %askCompress% == y (set Dumps=%Dumps%!\n!Image=%id%_sdc.e01) else set Dumps=%Dumps%!\n!Image=%id%_sdc.stepan
IF %askCompress% == y .\ressources\ftkimager\ftkimager.exe .\%idDir%\%id%_sdc.stepan .\%idDir%\%id%_sdc --e01 --compress 9
.\ressources\adb.exe pull /dev/block/sdd .\%idDir%\%id%_sdd.stepan 2>NUL
	IF %ERRORLEVEL% NEQ 0 (
		ECHO.
		ECHO SDD nicht gefunden.
		ECHO.
		goto NANDXEND
	)
IF %askCompress% == y (set Dumps=%Dumps%!\n!Image=%id%_sdd.e01) else set Dumps=%Dumps%!\n!Image=%id%_sdd.stepan
IF %askCompress% == y .\ressources\ftkimager\ftkimager.exe .\%idDir%\%id%_sdd.stepan .\%idDir%\%id%_sdd --e01 --compress 9
.\ressources\adb.exe pull /dev/block/sde .\%idDir%\%id%_sde.stepan 2>NUL
	IF %ERRORLEVEL% NEQ 0 (
		ECHO.
		ECHO SDE nicht gefunden.
		ECHO.
		goto NANDXEND
	)
IF %askCompress% == y (set Dumps=%Dumps%!\n!Image=%id%_sde.e01) else set Dumps=%Dumps%!\n!Image=%id%_sde.stepan
IF %askCompress% == y .\ressources\ftkimager\ftkimager.exe .\%idDir%\%id%_sde.stepan .\%idDir%\%id%_sde --e01 --compress 9
.\ressources\adb.exe pull /dev/block/sdf .\%idDir%\%id%_sdf.stepan 2>NUL
	IF %ERRORLEVEL% NEQ 0 (
		ECHO.
		ECHO SDF nicht gefunden.
		ECHO.
		goto NANDXEND
	)
IF %askCompress% == y (set Dumps=%Dumps%!\n!Image=%id%_sdf.e01) else set Dumps=%Dumps%!\n!Image=%id%_sdf.stepan
IF %askCompress% == y .\ressources\ftkimager\ftkimager.exe .\%idDir%\%id%_sdf.stepan .\%idDir%\%id%_sdf --e01 --compress 9

:NANDXEND
ECHO SDX erfolgreich
ECHO.
ECHO Interner Speicher erfolgreich kopiert
set General=!General!!\n!EndTime=%date% %time%
set ExtractionStatus=%ExtractionStatus%!\n!ExtractionStatus=Success

IF %askHash% == y goto HashSDA

:NANDX
.\ressources\adb.exe pull /dev/block/nanda .\%idDir%\%id%_nanda.stepan 2>NUL
IF %askCompress% == y (set Dumps=%Dumps%!\n!Image=%id%_nanda.e01) else set Dumps=%Dumps%!\n!Image=%id%_nanda.stepan
IF %askCompress% == y .\ressources\ftkimager\ftkimager.exe .\%idDir%\%id%_nanda.stepan .\%idDir%\%id%_nanda --e01 --compress 9	
IF %ERRORLEVEL% NEQ 0 (
	ECHO.
	ECHO nandX nicht gefunden. 
	ECHO Probiere stattdessen SDA.
	ECHO.
	goto SDA
) ELSE (
	ECHO nanda gesichert.
	.\ressources\adb.exe pull /dev/block/nandb .\%idDir%\%id%_nandb.stepan 2>NUL
	IF %ERRORLEVEL% NEQ 0 (
		ECHO.
		ECHO nandb nicht gefunden.
		ECHO.
		goto NANDXENDE
	)
	IF %askCompress% == y (set Dumps=%Dumps%!\n!Image=%id%_nandb.e01) else set Dumps=%Dumps%!\n!Image=%id%_nandb.stepan
	IF %askCompress% == y .\ressources\ftkimager\ftkimager.exe .\%idDir%\%id%_nandb.stepan .\%idDir%\%id%_nandb --e01 --compress 9	
	ECHO nandb gesichert.
	.\ressources\adb.exe pull /dev/block/nandc .\%idDir%\%id%_nandc.stepan 2>NUL
	IF %ERRORLEVEL% NEQ 0 (
		ECHO.
		ECHO nandc nicht gefunden.
		ECHO.
		goto NANDXENDE
	)
	IF %askCompress% == y (set Dumps=%Dumps%!\n!Image=%id%_nandc.e01) else set Dumps=%Dumps%!\n!Image=%id%_nandc.stepan
	IF %askCompress% == y .\ressources\ftkimager\ftkimager.exe .\%idDir%\%id%_nandc.stepan .\%idDir%\%id%_nandc --e01 --compress 9	
	ECHO nandc gesichert.
	.\ressources\adb.exe pull /dev/block/nandd .\%idDir%\%id%_nandd.stepan 2>NUL
	IF %ERRORLEVEL% NEQ 0 (
		ECHO.
		ECHO nandd nicht gefunden.
		ECHO.
		goto NANDXENDE
	)
	IF %askCompress% == y (set Dumps=%Dumps%!\n!Image=%id%_nandd.e01) else set Dumps=%Dumps%!\n!Image=%id%_nandd.stepan
	IF %askCompress% == y .\ressources\ftkimager\ftkimager.exe .\%idDir%\%id%_nandd.stepan .\%idDir%\%id%_nandd --e01 --compress 9
	ECHO nandd gesichert.
	.\ressources\adb.exe pull /dev/block/nande .\%idDir%\%id%_nande.stepan 2>NUL
	IF %ERRORLEVEL% NEQ 0 (
		ECHO.
		ECHO nande nicht gefunden.
		ECHO.
		goto NANDXENDE
	)
	IF %askCompress% == y (set Dumps=%Dumps%!\n!Image=%id%_nande.e01) else set Dumps=%Dumps%!\n!Image=%id%_nande.stepan
	IF %askCompress% == y .\ressources\ftkimager\ftkimager.exe .\%idDir%\%id%_nande.stepan .\%idDir%\%id%_nande --e01 --compress 9
	ECHO nande gesichert.
	.\ressources\adb.exe pull /dev/block/nandf .\%idDir%\%id%_nandf.stepan 2>NUL
		IF %ERRORLEVEL% NEQ 0 (
		ECHO.
		ECHO nandf nicht gefunden.
		ECHO.
		goto NANDXENDE
	)
	IF %askCompress% == y (set Dumps=%Dumps%!\n!Image=%id%_nandf.e01) else set Dumps=%Dumps%!\n!Image=%id%_nandf.stepan
	IF %askCompress% == y .\ressources\ftkimager\ftkimager.exe .\%idDir%\%id%_nandf.stepan .\%idDir%\%id%_nandf --e01 --compress 9
	ECHO nandf gesichert.
	.\ressources\adb.exe pull /dev/block/nandg .\%idDir%\%id%_nandg.stepan 2>NUL
		IF %ERRORLEVEL% NEQ 0 (
		ECHO.
		ECHO nandg nicht gefunden.
		ECHO.
		goto NANDXENDE
	)
	IF %askCompress% == y (set Dumps=%Dumps%!\n!Image=%id%_nandg.e01) else set Dumps=%Dumps%!\n!Image=%id%_nandg.stepan
	IF %askCompress% == y .\ressources\ftkimager\ftkimager.exe .\%idDir%\%id%_nandg.stepan .\%idDir%\%id%_nandg --e01 --compress 9
	ECHO nandg gesichert.
	.\ressources\adb.exe pull /dev/block/nandh .\%idDir%\%id%_nandh.stepan 2>NUL
		IF %ERRORLEVEL% NEQ 0 (
		ECHO.
		ECHO nandh nicht gefunden.
		ECHO.
		goto NANDXENDE
	)
	IF %askCompress% == y (set Dumps=%Dumps%!\n!Image=%id%_nandh.e01) else set Dumps=%Dumps%!\n!Image=%id%_nandh.stepan
	IF %askCompress% == y .\ressources\ftkimager\ftkimager.exe .\%idDir%\%id%_nandh.stepan .\%idDir%\%id%_nandh --e01 --compress 9
	ECHO nandh gesichert.
	.\ressources\adb.exe pull /dev/block/nandi .\%idDir%\%id%_nandi.stepan 2>NUL
		IF %ERRORLEVEL% NEQ 0 (
		ECHO.
		ECHO nandi nicht gefunden.
		ECHO.
		goto NANDXENDE
	)
	IF %askCompress% == y (set Dumps=%Dumps%!\n!Image=%id%_nandi.e01) else set Dumps=%Dumps%!\n!Image=%id%_nandi.stepan
	IF %askCompress% == y .\ressources\ftkimager\ftkimager.exe .\%idDir%\%id%_nandi.stepan .\%idDir%\%id%_nandi --e01 --compress 9
	ECHO nandi gesichert.
	.\ressources\adb.exe pull /dev/block/nandj .\%idDir%\%id%_nandj.stepan 2>NUL
		IF %ERRORLEVEL% NEQ 0 (
		ECHO.
		ECHO nandj nicht gefunden.
		ECHO.
		goto NANDXENDE
	)
	IF %askCompress% == y (set Dumps=%Dumps%!\n!Image=%id%_nandj.e01) else set Dumps=%Dumps%!\n!Image=%id%_nandj.stepan
	IF %askCompress% == y .\ressources\ftkimager\ftkimager.exe .\%idDir%\%id%_nandj.stepan .\%idDir%\%id%_nandj --e01 --compress 9
	ECHO nandj gesichert.
	.\ressources\adb.exe pull /dev/block/nandk .\%idDir%\%id%_nandk.stepan 2>NUL
		IF %ERRORLEVEL% NEQ 0 (
		ECHO.
		ECHO nandk nicht gefunden.
		ECHO.
		goto NANDXENDE
	)
	IF %askCompress% == y (set Dumps=%Dumps%!\n!Image=\%id%_nandk.e01) else set Dumps=%Dumps%!\n!Image=%id%_nandk.stepan
	IF %askCompress% == y .\ressources\ftkimager\ftkimager.exe .\%idDir%\%id%_nandk.stepan .\%idDir%\%id%_nandk --e01 --compress 9
	ECHO nandk gesichert.
	ECHO.
	
	:NANDXENDE
	ECHO nandX erfolgreich
	ECHO.	
	set General=!General!!\n!EndTime=%date% %time%
	set ExtractionStatus=%ExtractionStatus%!\n!ExtractionStatus=Success
	GOTO END
)

:END
::Erstelle die UFD-Datei
ECHO.  2>.\%idDir%\%id%.ufd

::Schreibt den Kram der immer gleich ist in die ufd/variablen
set General=!General!!\n!AcquisitionTool=TWRP-Dumper
set General=!General!!\n!FullName=%id%
set General=!General!!\n!Device=ANDROID_GENERIC
set General=!General!!\n!ExtractionType=Physical
set General=!General!!\n!ExtractionMethod=ANDROID_ADB
set General=!General!!\n!IsEncrypted=False
set General=!General!!\n!IsEncryptedBySystem=False
set General=!General!!\n!UfdVer=1.2
set General=!General!!\n!ExtractionSoftwareVersion=5.3.6.7
set General=!General!!\n!IsPartialData=False

::Schreibt die Variablen in die ufd-Datei
ECHO !Dumps! >> .\%idDir%\%id%.ufd
ECHO !General! >> .\%idDir%\%id%.ufd
ECHO !DeviceInfo! >> .\%idDir%\%id%.ufd
ECHO !ExtractionStatus! >> .\%idDir%\%id%.ufd

IF NOT %askHash% == y SET SHA256=!SHA256!!\n!%ImageName%=Not hashed with this tool 
IF NOT %askHash% == y SET Hash=!Hash!!\n!%ImageName%=Not hashed with this tool 

ECHO !SHA256! >> .\%idDir%\%id%.ufd
ECHO !Hash! >> .\%idDir%\%id%.ufd

::Lösche die Temp Datei
DEL /f .\%idDir%\prop.csv
DEL tmp2.txt
IF %askCompress% == y (DEL /S *.stepan)

::Beende ADB Server
.\ressources\adb.exe kill-server

ECHO.
ECHO TWRP-Dumper abgeschlossen.
pause >NUL