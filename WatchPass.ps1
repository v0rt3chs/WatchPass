<# ============================================================ 
Written By: Curtis Dawkins
Date Created: 2023
Last Updated: 3/11/2025
Purpose: Streamline the account compromise containment process.
============================================================ #> 

#Command line args
param($user,[int]$refresh,[switch]$verbose,[switch]$reset,[switch]$revoke,[switch]$contain)

function Reset-Pass {
    if ($verbose){
        Write-Host "Trying to reset user's password..."`n -ForegroundColor Magenta
    }
    try{$upn = (get-aduser $Env:UserName).UserPrincipalName}
    catch{
        Write-Warning -Message "There was an error getting your email address. If you are not in the office or on the VPN, this is expected."
        $upn= Read-Host "Please enter your email address: "
    }
    try {Connect-AzureAD -AccountId $upn | Out-Null}
    catch{Write-Warning -Message "There was an error connecting to AzureAD Powershell. Make sure you have the AzureAD PowerShell module installed!"; exit}
    try{$userUPN=(get-aduser $user).UserPrincipalName}
    catch{
        Write-Warning -Message "Could not get user's UPN automatically. If you are not in the office or on the VPN, this is expected. "
        $userUPN= Read-Host "Please enter the user's email address: "
    }
    if ($verbose){
        Write-Host "Resetting Azure password for"$userUPN"..."`n -ForegroundColor Magenta
    }
    $sample = -join ((65..90) + (97..122) + (33..64) | Get-Random -Count 64 | % {[char]$_})
    $pswd = ConvertTo-SecureString $sample -AsPlainText -Force
    $sample=$null
    try{Set-AzureADUserPassword -ObjectId $userUPN -Password $pswd}
    catch{Write-Warning "There was an error resetting the password. Are you an Authentication Administator or Privileged Authentication Administrator?"; $pswd=$null; exit}
    Write-Host "Azure Password reset completed successfully at: "$((date))`n -ForegroundColor Green
    sleep 2 #this is to avoid the password resets overlapping eachother
    if ($verbose){
        Write-Host "Resetting on-prem AD password for"$userUPN"..."`n -ForegroundColor Magenta
    }
    try{Set-ADAccountPassword -Identity $user -Reset -NewPassword $pswd}
    catch{
        Write-Warning "There was an error resetting the password in on-prem AD. Are you on the production network or VPN? Do you have permissions to reset this account's password?"
        $pswd=$null
        exit 
    }
    Write-Host "On-Prem AD Password reset completed successfully at: "$((date))`n -ForegroundColor Green
    $pswd=$null
}

function Revoke-Sessions {
    if ($verbose){
        Write-Host "Trying to revoke user's sessions..."`n -ForegroundColor Magenta
    }
    try{$upn = (get-aduser $Env:UserName).UserPrincipalName}
    catch{
        Write-Warning -Message "There was an error getting your email address. If you are not in the office or on the VPN, this is expected. "
        $upn= Read-Host "Please enter your email address: "
    }
    try {Connect-AzureAD -AccountId $upn | Out-Null}
    catch{Write-Warning -Message "There was an error connecting to AzureAD Powershell. Make sure you have the AzureAD PowerShell module installed!"; exit}
    try{$userUPN=(get-aduser $user).UserPrincipalName}
    catch{
        Write-Warning -Message "Could not get user's UPN automatically. If you are not in the office or on the VPN, this is expected. "
        $userUPN= Read-Host "Please enter the user's email address: "
    }
    try{Revoke-AzureADUserAllRefreshToken -ObjectId $userUPN}
    catch{
        Write-Warning -Message "There was an error revoking the user's sessions. Are you an Authentication Administator or Privileged Authentication Administrator? "
        exit
    }
    Write-Host "Sessions revoked successfully at: "$((date)) -ForegroundColor Green
}

function Contain{
    if ($verbose){
        Write-Host "Trying to reset user's password and revoke user's sessions..."`n -ForegroundColor Magenta
    }
    try{$upn = (get-aduser $Env:UserName).UserPrincipalName}
    catch{
        Write-Warning -Message "There was an error getting your email address. If you are not in the office or on the VPN, this is expected."
        $upn= Read-Host "Please enter your email address: "
    }
    try {Connect-AzureAD -AccountId $upn | Out-Null}
    catch{Write-Warning -Message "There was an error connecting to AzureAD Powershell. Make sure you have the AzureAD PowerShell module installed!"; exit}
    try{$userUPN=(get-aduser $user).UserPrincipalName}
    catch{
        Write-Warning -Message "Could not get user's UPN automatically. If you are not in the office or on the VPN, this is expected. "
        $userUPN= Read-Host "Please enter the user's email address: "
    }
    if ($verbose){
        Write-Host "Resetting Azure password for"$userUPN"..."`n -ForegroundColor Magenta
    }
    $sample = -join ((65..90) + (97..122) + (33..64) | Get-Random -Count 64 | % {[char]$_})
    $pswd = ConvertTo-SecureString $sample -AsPlainText -Force
    $sample=$null
    try{Set-AzureADUserPassword -ObjectId $userUPN -Password $pswd}
    catch{Write-Warning "There was an error resetting the password in Azure. Are you an Authentication Administator or Privileged Authentication Administrator?"; exit}
    Write-Host "Azure Password reset completed successfully at: "$((date))`n -ForegroundColor Green
    #on-prem password reset
    sleep 2 #this is to avoid the password resets overlapping eachother
    if ($verbose){
        Write-Host "Resetting on-prem AD password for"$userUPN"..."`n -ForegroundColor Magenta
    }
    try{Set-ADAccountPassword -Identity $user -Reset -NewPassword $pswd}
    catch{
        Write-Warning "There was an error resetting the password in on-prem AD. Are you on the production network or VPN?"
        exit 
    }
    Write-Host "On-Prem AD Password reset completed successfully at: "$((date))`n -ForegroundColor Green

    if ($verbose){
        Write-Host "Revoking sessions for"$userUPN"..."`n -ForegroundColor Magenta
    }
    try{Revoke-AzureADUserAllRefreshToken -ObjectId $userUPN}
    catch{
        Write-Warning -Message "There was an error revoking the user's sessions. Are you an Authentication Administator or Privileged Authentication Administrator? "
        exit
    }
    Write-Host "Sessions revoked successfully at: "$((date)) -ForegroundColor Green
}

#Error Checking
if ($PSBoundParameters.ContainsKey('user')){
    $start=date
    write-host `n"User Passed: "
    write-host "$((get-aduser $user).Name)" -ForegroundColor Magenta
    write-host `n"Watch Pass was started at: "
    write-host $start -ForegroundColor Magenta
    if ($verbose){
        write-host `n"verbose mode is enabled" -ForegroundColor Green
    }
    
} else {
    write-host "Usage: .\WatchPass.ps1 -user <username> [-refresh <refresh-rate-in-seconds>] [ -contain | -reset | -revoke | -verbose ]" -ForegroundColor Red
    exit
}

#refresh rate
if ($PSBoundParameters.ContainsKey('refresh') -and $refresh -le 3600){
    $rr=$refresh
} else {
    if ($refresh -gt 3600){
        write-host "Refresh value set higher than maximum (3600 seconds). Value has been set to default of 120 seconds." -ForegroundColor Yellow
    }
    $rr=120 #default refresh rate (in seconds) if none is specified
}

Write-Host `n$user"'s last password reset occurred: "
$last=(Get-ADUser $user -properties *).passwordlastset
Write-Host $last `n -ForegroundColor Magenta
Write-Host @"
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣠⣤⣴⡶⠶⠾⠟⠛⠛⠛⠛⠷⠶⣦⣤⣀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀       
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣠⣶⠿⠛⠉⣁⣠⠤⠤⠀⠀⠀⠀⠀⠀⠀⠘⠷⢬⣙⡛⠷⣦⣄⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀      
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣠⡶⠟⢉⣠⠴⠚⠉⠁⣀⡀⠠⠀⠐⠂⠀⠀⠀⠀⠀⠀⠀⠀⠉⠓⠦⣍⡻⢷⣤⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀       
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣴⠿⢋⡤⠞⢉⣠⡤⠖⢚⣉⣁⣤⣤⣴⣦⣤⣤⣄⣀⣀⠀⠀⠘⠲⢤⡀⠀⠈⠙⠲⣌⡛⢷⣤⡀⠀⠀⠀⠀⠀⠀⠀     
⠀⠀⠀⠀⠀⠀⠀⠀⢀⣤⡾⢋⣡⠞⣋⠴⠚⣉⣥⡴⠾⠟⠛⢉⣉⣀⣠⣤⣤⣭⣍⣉⣛⡻⠶⣦⣤⣀⠉⠓⠦⣄⠀⠀⠙⢦⡉⠻⣦⡀⠀⠀⠀⠀⠀    
⠀⠀⠀⠀⠀⠀⣀⣴⠟⢁⣴⣫⠷⢛⣡⣴⠟⠋⣁⣤⣴⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⠟⠿⠿⣿⣶⣬⣝⡻⢶⣤⡀⠙⠂⢀⠀⠘⠢⡈⠻⣶⣄⠀⠀⠀   
⠀⠀⠀⠀⣠⡾⠛⠁⢠⡿⠛⣡⣶⠟⢋⣤⣶⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣀⣤⣤⠀⠻⣿⣿⣿⣷⣮⣟⠷⣦⣜⠀⠀⠀⠀⠀⠈⠛⢷⣄⠀   
⠀⢀⣰⡾⠋⠀⠀⠀⢋⣴⠿⢋⣦⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⡇⠈⣿⢿⣿⣿⣿⣿⣾⣝⡻⣦⣄⠀⠀⠀⠀⠀⠙⠷   
⣰⡿⠋⠀⠀⠀⣠⡾⢛⣡⣶⡿⠛⣿⣿⣿⣿⠻⣿⠸⣏⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⡇⠀⣿⠈⢻⣿⢿⣿⢿⣿⣿⣷⣭⣀⠀⠀⠀⠀⠀⠀   
⠀⠀⠀⠀⣤⣾⣯⣴⡿⠛⠋⠀⠀⢹⡼⣿⣿⠀⢿⡀⠉⠈⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⢣⡇⢀⡿⠀⣸⡏⢸⡟⢘⣿⠁⠙⠛⣻⣷⠀⢸⡆⠀⠀   
⠀⠀⠀⠘⣯⣾⡟⢷⡄⠀⠀⠀⠀⠀⠀⠙⢿⣆⠘⣷⡀⠀⠀⠙⠿⣿⣿⣿⣿⣿⣿⣿⡿⢋⡾⢀⡼⠁⣰⡟⠀⠞⠁⢸⡏⠀⢀⣴⣿⠁⠀⣸⠇⠀⠀    
⠀⠀⣰⣿⢛⣿⡇⠘⠃⠀⠀⠀⠀⠀⠀⠀⠈⠻⣧⣈⠃⠀⠀⠀⠀⠀⠈⠉⠛⠛⠋⠉⠴⠋⣠⠞⢀⣼⠏⠀⠀⠀⠀⡞⢀⣴⣿⣿⠏⠀⠀⠁⠀⠀⠀     
⠀⠀⠙⠛⠛⠛⠿⠿⣷⣦⣄⡐⢦⣀⠀⠀⠀⠀⠈⠛⢷⣦⣀⡀⠀⠀⠀⠀⠀⠀⠀⠀⢠⢞⣡⣴⠟⠁⠀⠀⠀⢀⣠⣾⣿⣿⠟⡁⠀⠀⠀⠀⠀⠀⠀     
⠀⠀⡀⠀⠀⠀⠀⠀⠀⠈⠙⠻⢶⣭⣟⡦⣤⣀⡀⠀⠀⠉⠛⠻⠿⠶⣶⣤⣤⣤⣶⣶⠿⠟⠋⠀⠀⠀⢀⣠⣶⣿⣿⡿⠋⣠⣾⠇⣠⠀⠀⠀⠀⠀⠀    
⠀⠘⠛⠛⠛⠛⠻⢷⣦⣀⠀⠀⠀⠈⠉⠛⠷⢮⣽⣓⡲⠤⣄⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣀⣤⣶⣿⣿⡿⠛⠉⢁⣴⠟⢡⡾⠃⠀⠀⠀⠀⠀⠀    
⠀⠀⠀⠀⠀⠀⠸⣄⡈⠛⠿⣶⣤⣄⡀⠀⠀⠀⠀⠉⠙⠛⠿⠷⣶⣦⣤⣤⣤⣤⣴⣶⣶⡿⠿⠿⠟⠛⠋⠁⢀⣠⡾⠛⢁⡴⠋⣠⠆⢀⡴⠀⠀⠀⠀   
⠀⠀⠀⠀⠀⠀⢻⣌⡛⠶⣤⣀⠈⠙⠛⠿⢶⣦⣤⣄⣀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣤⣾⠟⠋⣠⡶⢋⡠⠞⠁⠠⠋⠀⠀⠀⠀⠀     
⠀⠀⠀⠀⠀⠀⠷⣍⡛⠳⢶⣭⠅⠀⠀⠀⠀⠀⠈⠉⢛⠛⠿⠷⢶⣶⣦⣤⣤⣤⣤⣤⣤⣴⣶⡾⠟⠛⠉⠀⠀⠚⠡⠖⣋⡤⠖⠉⠀⠀⠀⠀⠀⠀⠀    
⠀⠀⠀⠀⠀⠀⠀⠀⠉⠙⠓⠃⠀⠀⠀⠀⠀⠀⠀⠀⠈⠳⣶⠦⠤⠤⠤⠤⣄⠀⢀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀        
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⣉⣓⣒⡒⠒⠶⠦⠀⢲⣄⣀⣀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀        
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠉⠉⠉⠉⠉⠉⠉⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀                     

"@ -ForegroundColor white

#check for flags that override normal process flow
if ($contain -or ($reset -and $revoke)){
    Contain
    exit
}

if ($reset){
    Reset-Pass
    exit
}
if ($revoke){
    Revoke-Sessions
    exit
}


Write-Host "        <->        WATCHING FOR PASSWORD RESET!!        <->"`n
While (1){
    $new=(Get-ADUser $user -properties *).passwordlastset
    $current=date
    if ($last -ne $new){
        write-host "Password has been updated as of "$new"!" -ForegroundColor Green
        exit
    } else {
        if (($current-$start).Hours -eq 1){
            write-host "Password was not reset after an hour. Password should be reset administratively!" -ForegroundColor Red
            $rst = read-host "Would you like to try and reset it? (This is a good time to make sure you are elevated!) (y/n) "
            if ($rst -eq "y" -or $rst -eq "Y"){
                Reset-Pass
                $rst2 = read-host "Would you also like to try to revoke sessions? (y/n)"
                if ($rst2 -eq "y" -or $rst2 -eq "Y"){
                    Revoke-Sessions
                    exit
                }
                else{
                    write-host "Password was reset, but sessions were not revoked!" -ForegroundColor Yellow
                    exit
                }
            }
            else{
                write-host "Password was not reset and sessions were not revoked!" -ForegroundColor Red
                exit
            }
        }
        if ($verbose){
            write-host "Password not changed as of -> " -NoNewline
            write-host $current.TimeOfDay -ForegroundColor Red
        }
        sleep($rr);
        $last=$new
    }
}