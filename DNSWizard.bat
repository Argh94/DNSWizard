@echo off
setlocal EnableDelayedExpansion
title DNS Changer - Advanced Restore Version
color 0a

REM ---- Config ----
set "logFile=DNSChanger_log.txt"

REM ---- Check for Administrator privileges ----
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo This script requires Administrator privileges. Please run as Administrator.
    pause
    exit /b
)

REM ---- Fix datetime format for consistent sorting ----
for /f "tokens=1-3 delims=/ " %%a in ("%date%") do set "fdate=%%c-%%b-%%a"
set "ftime=%time::=-%"
set "datetime=!fdate!_!ftime: =0!"

REM ---- Backup current DNS settings (IPv4 & IPv6) ----
echo Backing up current DNS settings...
(for /f "tokens=2 delims=:" %%a in ('netsh interface show interface ^| find "Connected"') do (
    set "interface=%%a"
    set "interface=!interface:~1!"
    netsh interface ipv4 show dnsservers name="!interface!" > "!interface!_dns_backup_!datetime!.txt"
    netsh interface ipv6 show dnsservers name="!interface!" >> "!interface!_dns_backup_!datetime!.txt"
)) >nul 2>&1

REM ---- DNS Provider List (IPv4|IPv4|IPv6|IPv6|DoH Support) ----
set "dns[1]=Begzar|185.55.226.26|185.55.225.25|2a0c:5a80::feed:1|2a0c:5a80::feed:2|No"
set "dns[2]=Shecan|178.22.122.100|185.51.200.2|2a06:fb00:1::1|2a06:fb00:1::2|No"
set "dns[3]=ShelterTM|94.103.125.157|94.103.125.158|::|::|No"
set "dns[4]=Electro|78.157.42.100|78.157.42.101|::|::|No"
set "dns[5]=Radar|10.202.10.10|10.202.10.11|::|::|No"
set "dns[6]=403|10.202.10.102|10.202.10.202|::|::|No"
set "dns[7]=Google Public|8.8.8.8|8.8.4.4|2001:4860:4860::8888|2001:4860:4860::8844|Yes (dns.google)"
set "dns[8]=OpenDNS|208.67.222.222|208.67.220.220|2620:0:ccc::2|2620:0:ccd::2|Yes (dns.umbrella.com)"
set "dns[9]=Cloudflare|1.1.1.1|1.0.0.1|2606:4700:4700::1111|2606:4700:4700::1001|Yes (1dot1dot1dot1.cloudflare-dns.com)"
set "dns[10]=Quad9|9.9.9.9|149.112.112.112|2620:fe::fe|2620:fe::9|Yes (dns.quad9.net)"
set "dns[11]=Norton ConnectSafe|199.85.126.10|199.85.127.10|::|::|No"
set "dns[12]=DNS.Watch|84.200.69.80|84.200.70.40|::|::|No"
set "dns[13]=DNS Advantage|156.154.70.1|156.154.71.1|::|::|No"
set "dns[14]=Dyn|216.146.35.35|216.146.36.36|::|::|No"
set "dns[15]=Level3|209.244.0.3|209.244.0.4|::|::|No"
set "dns[16]=Comodo Secure DNS|8.26.56.26|8.20.247.20|::|::|No"
set "dns[17]=SafeDNS|195.46.39.39|195.46.39.40|::|::|No"
set "dns[18]=Verisign|64.6.64.6|64.6.65.6|::|::|No"
set "dns[19]=Yandex.DNS|77.88.8.8|77.88.8.1|::|::|No"
set "dns[20]=OpenNIC|96.90.175.167|193.183.98.154|::|::|No"
set "dns[21]=GreenTeamDNS|81.218.119.11|209.88.198.133|::|::|No"
set "dns[22]=SmartViper|208.76.50.50|208.76.51.51|::|::|No"
set "dns[23]=UncensoredDNS|91.239.100.100|89.233.43.71|::|::|No"
set "dns[24]=Alternate DNS|198.101.242.72|198.101.242.72|::|::|No"
set "dns[25]=FreeDNS|37.235.1.174|37.235.1.177|::|::|No"
set "dns[26]=DHCP (Automatic)|DHCP|DHCP|DHCP|DHCP|No"
set "dns[27]=Restore Previous|RESTORE|RESTORE|RESTORE|RESTORE|No"
set "dns[28]=Manage Backups|MANAGE|MANAGE|MANAGE|MANAGE|No"
set "dns[29]=Exit|EXIT|EXIT|EXIT|EXIT|No"

:menu
cls
echo ^|==================================================^|
echo ^|         DNS Changer - Advanced Restore Version     ^|
echo ^|==================================================^|
echo.
for /L %%i in (1,1,29) do (
    for /f "tokens=1-6 delims=|" %%a in ("!dns[%%i]!") do (
        if "%%d"=="::" (
            echo %%i. %%a (IPv4: %%b/%%c, DoH: %%f)
        ) else (
            echo %%i. %%a (IPv4: %%b/%%c, IPv6: %%d/%%e, DoH: %%f)
        )
    )
)
echo.
set /p choice="Enter the number of your choice (1-29): "

REM ---- Validate choice ----
if %choice% lss 1 set choice=1
if %choice% gtr 29 set choice=29

if %choice%==29 exit /b
if %choice%==28 goto manage_backups

REM ---- Extract selected DNS ----
for /f "tokens=1-6 delims=|" %%a in ("!dns[%choice%]!") do (
    set provider=%%a
    set primaryDNS=%%b
    set secondaryDNS=%%c
    set primaryDNSv6=%%d
    set secondaryDNSv6=%%e
    set dohSupport=%%f
)

REM ---- Check if DNS servers are reachable (Test multiple domains and ping) ----
if /i not "!primaryDNS!"=="DHCP" if /i not "!primaryDNS!"=="RESTORE" if /i not "!primaryDNS!"=="MANAGE" (
    set "testFailed=0"
    for %%d in (wikipedia.org bbc.com cloudflare.com github.com) do (
        nslookup %%d !primaryDNS! >nul 2>&1
        if !errorlevel! neq 0 set /a testFailed+=1
    )
    ping -n 1 !primaryDNS! >nul 2>&1
    if !errorlevel! neq 0 set /a testFailed+=1
    if !testFailed! geq 3 (
        color 0C
        echo [WARNING] Primary DNS !primaryDNS! is not resolving queries or not reachable.
        color 0A
        pause
    )
    set "testFailed=0"
    for %%d in (wikipedia.org bbc.com cloudflare.com github.com) do (
        nslookup %%d !secondaryDNS! >nul 2>&1
        if !errorlevel! neq 0 set /a testFailed+=1
    )
    ping -n 1 !secondaryDNS! >nul 2>&1
    if !errorlevel! neq 0 set /a testFailed+=1
    if !testFailed! geq 3 (
        color 0C
        echo [WARNING] Secondary DNS !secondaryDNS! is not resolving queries or not reachable.
        color 0A
        pause
    )
)

REM ---- Apply DNS settings ----
echo Applying DNS settings...
for /f "tokens=2 delims=:" %%a in ('netsh interface show interface ^| find "Connected"') do (
    set "interface=%%a"
    set "interface=!interface:~1!"

    if /i "!primaryDNS!"=="DHCP" (
        netsh interface ipv4 set dnsservers name="!interface!" source=dhcp
        if !errorlevel! neq 0 echo [ERROR] Failed to set IPv4 DHCP on !interface!
        netsh interface ipv6 set dnsservers name="!interface!" source=dhcp
        if !errorlevel! neq 0 echo [ERROR] Failed to set IPv6 DHCP on !interface!
        echo [%date% %time%] Set DNS for !interface! to DHCP.>> %logFile%
    ) else if /i "!primaryDNS!"=="RESTORE" (
        REM ---- Restore DNS from backup ----
        call :restore_dns "!interface!"
        echo [%date% %time%] Restored previous DNS for !interface! from backup.>> %logFile%
    ) else (
        netsh interface ipv4 set dnsservers name="!interface!" static !primaryDNS! >nul
        if !errorlevel! neq 0 (
            echo [ERROR] Failed to set primary IPv4 on !interface!
        ) else (
            netsh interface ipv4 add dnsservers name="!interface!" !secondaryDNS! index=2 >nul
            if !errorlevel! neq 0 echo [ERROR] Failed to set secondary IPv4 on !interface!
        )
        
        REM ---- Check if IPv6 is enabled ----
        netsh interface ipv6 show interface "!interface!" | find "enabled" >nul
        if !errorlevel! equ 0 (
            if not "!primaryDNSv6!"=="::" (
                netsh interface ipv6 set dnsservers name="!interface!" static !primaryDNSv6! >nul
                if !errorlevel! neq 0 (
                    echo [ERROR] Failed to set primary IPv6 on !interface!
                ) else (
                    netsh interface ipv6 add dnsservers name="!interface!" !secondaryDNSv6! index=2 >nul
                    if !errorlevel! neq 0 echo [ERROR] Failed to set secondary IPv6 on !interface!
                )
            )
        ) else (
            echo [INFO] IPv6 is not enabled on !interface!. Skipping IPv6 DNS settings.
        )
        echo [%date% %time%] Set DNS for !interface! to !provider! >> %logFile%
    )
)

REM ---- Flush DNS cache ----
echo Flushing DNS cache...
ipconfig /flushdns >nul 2>&1

echo.
echo DNS servers set to !provider!
if /i "!dohSupport!"=="Yes" (
    echo Note: !provider! supports DNS over HTTPS (DoH). Configure it manually via browser or OS settings for enhanced security.
)
echo DNS cache flushed successfully.

echo.
echo Press any key to return to the menu...
pause >nul
goto menu

REM ---- Restore DNS subroutine ----
:restore_dns
set "interface=%~1"
set "backup_file="
for /f "delims=" %%b in ('dir /b /o-d "%interface%_dns_backup_*.txt" 2^>nul') do (
    set "backup_file=%%b"
    goto :found_backup
)
echo No backup found for %interface%. Setting to DHCP.
netsh interface ipv4 set dnsservers name="%interface%" source=dhcp
netsh interface ipv6 set dnsservers name="%interface%" source=dhcp
goto :eof

:found_backup
set "v4list="
set "v6list="
set "mode="

for /f "usebackq tokens=*" %%b in ("%backup_file%") do (
    set "line=%%b"
    set "line=!line: =!"
    
    if "!line!"=="StaticallyConfiguredDNSServers:" (
        set "mode=static"
    ) else if "!line!"=="DNSServers:" (
        set "mode=static"
    ) else if defined mode (
        echo !line! | findstr /r /c:"^[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*$" >nul
        if !errorlevel! equ 0 (
            if not defined v4list (set "v4list=!line!") else set "v4list=!v4list! !line!"
        )
        
        echo !line! | findstr /r /c:"^[0-9a-fA-F:][0-9a-fA-F:]*$" >nul
        if !errorlevel! equ 0 (
            if not defined v6list (set "v6list=!line!") else set "v6list=!v6list! !line!"
        )
    )
)

if defined v4list (
    set "first=1"
    for %%s in (!v4list!) do (
        if !first! equ 1 (
            netsh interface ipv4 set dnsservers name="%interface%" static %%s >nul
            set "first=0"
        ) else (
            netsh interface ipv4 add dnsservers name="%interface%" %%s index=2 >nul
        )
    )
) else (
    netsh interface ipv4 set dnsservers name="%interface%" source=dhcp >nul
)

if defined v6list (
    set "first=1"
    for %%s in (!v6list!) do (
        if !first! equ 1 (
            netsh interface ipv6 set dnsservers name="%interface%" static %%s >nul
            set "first=0"
        ) else (
            netsh interface ipv6 add dnsservers name="%interface%" %%s index=2 >nul
        )
    )
) else (
    netsh interface ipv6 set dnsservers name="%interface%" source=dhcp >nul
)
goto :eof

REM ---- Manage Backups Subroutine ----
:manage_backups
cls
echo ^|==================================================^|
echo ^|            Manage Backup Files                   ^|
echo ^|==================================================^|
echo.
echo 1. List all backup files
echo 2. Delete all backup files
echo 3. Return to main menu
echo.
set /p backup_choice="Enter your choice (1-3): "

if %backup_choice%==1 (
    dir /b /o-d "*_dns_backup_*.txt" 2>nul || echo No backup files found.
    pause
    goto manage_backups
)
if %backup_choice%==2 (
    echo Deleting all backup files...
    del /q "*_dns_backup_*.txt" 2>nul
    echo All backup files deleted.
    echo [%date% %time%] Deleted all backup files.>> %logFile%
    pause
    goto manage_backups
)
if %backup_choice%==3 goto menu
goto manage_backups
