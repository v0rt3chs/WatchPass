## Overview

`WatchPass` was originally written during a time where account compromises were fairly frequent. Its primary functionality was to monitor an account for a password reset from the Support team. Over time, I started adding more functionality to it that would help us automate the process of containing O365 account compromise (and other identity) incidents ourselves.

## Prerequisites

- VPN or on-premises network connectivity for password resets in on-prem AD
- AzureAD PowerShell Module
- ActiveDirectory PowerShell Module
- Authentication Administrator or Privileged Authentication Administrator depending on privileges of impacted user
- Privileges to reset passwords in on-prem AD

## Basic Usage

- Watch for password reset for user at set interval of 30 seconds
```powershell
.\WatchPass.ps1 -user cdawkins -refresh 30
```
If no refresh rate is specified, the default will be 120 seconds. After one hour, you will be asked if you would like `WatchPass` to reset the password for you. Doing password reset this way does *not* revoke sessions. The `-verbose` switch can be added to get updates at each `refresh` interval. If you are wanting to take a screenshot for documentation, leaving verbose out might be best in this case.

- Reset user password
```powershell
.\WatchPass.ps1 -user cdawkins -reset
```
When `WatchPass` does a password reset, it prioritizes the Entra password reset first. It will try grabbing the UPN from on-prem AD right away though, so you may be prompted to manually input the user's email address if on-prem network connectivity cannot be established. As long as you have proper permissions in Entra, the Entra password reset will work smoothly. Then the On-prem password reset will kickoff using the same password sample. As long as you have permissions to reset the user's password and on-prem network connectivity, the password reset should work fine. As always the `-verbose` switch may be included to provide more details.

- Revoke user sessions
```powershell
.\WatchPass.ps1 -user cdawkins -revoke
```
There may be times where you only want to revoke a user's sessions. This may be preferred after a user's password has already been reset by another IT department member. `WatchPass` will try to establish *your* email address using on-prem AD, if for some reason you are not in the office or on the on-prem network, you will need to enter your own email address. This is used to connect you to the AzureAD PowerShell module. Another check for the user's UPN will occur on-prem, you may have to manually enter the email address if `WatchPass` cannot get it for you. The `-verbose` switch can be added for status updates and more info.

- Contain user account
```powershell
.\WatchPass.ps1 -user cdawkins -contain
```
Many times you will want to both reset the password and revoke user sessions to fully contain an account compromise. Passing the `-contain` switch will function the same as passing both the `-reset` and `-revoke` switches together. The password resets will always be processed before containment.

## Parameters

- `-user` - this is a required parameter in which you pass the username of the user you are performing actions on (do not include @domain.whatever).

- `-refresh` - this is an optional parameter for watching for password resets. This defines the rate (in seconds) at which `WatchPass` will check on-prem AD for a changed password. If not set during a password watch, the default value is 120 seconds. This value cannot be higher than 3600 seconds. If you set it higher, it will automatically default back to 120 seconds.

- `-reset` - this is an optional parameter that tells `WatchPass` to try to reset the user's password in both Entra and on-premises AD.

- `-revoke` - this is an optional parameter that tells `WatchPass` to try to revoke the user's sessions in Entra.

- `-contain` - this is an optional parameter that tells `WatchPass` to try and reset and revoke user sessions. It combines the functionality of `-reset` and `-revoke` parameters.

- `-verbose` - this is an optional parameter that provides more information for the admin running `WatchPass`. This can be beneficial for troubleshooting errors or providing more context in screenshots. In certain cases though such as watching for password resets, it could make your screenshot much larger as it will print a line for each check depending on `-refresh` value.

## Other notes

- `WatchPass` password resets are conducted based on the zero knowledge concept. The plaintext sample generated for a password is a 64 character string including uppercase letters, lowercase letters, numbers, and symbols. This plaintext sample string is never printed to the console or stored permanently anywhere else on the system. As soon as the plaintext sample is generated, a Microsoft secure string is created using it. Immediately after the secure string is created, the plaintext sample string is destroyed and deallocated in memory. After both password resets are done, or if a terminating error is reached during password reset attempts, the secure string is also destroyed and deallocated in memory. Resetting the password to something unknown is *intentional* as another administrator can simply reset the password again when they are ready to help the user get signed back in. This way, no one ever needs to know the password to make the account secure, which also eliminates the risk of insider threat until the password is reset again.

- SHA-256 Hash of most current version of `WatchPass`
```
84481974C66875D79ECE6580A190F71EE6D276BE115F019FDE89090BBCE084C3
```

## Known Issues

- In its current state, `WatchPass` has a heavy reliance on on-premises Active Directory. My intention was to fix this by separating AD and Azure (Entra) as much as possible, but I did not have enough time to do so before I left. I may continue development of this tool if there is any interest in it.

- Password reset watching functionality currently only works for an hour before prompting for password reset/revoking sessions. Regardless of what you opt into or out of at this point, `WatchPass` will terminate without watching for password resets any longer. This could easily be fixed with a new switch.

- If you exclude the `-verbose` switch from a normal password watch use case, you also forfeit your ability to have password reset and session token revocation with verbosity.

- While watching for password resets, if the password is reset in such a way that does not create a "passwordlastset" date in ActiveDirectory, the output from the script will also not display a date for what time the password was reset. This may be a good use case for `-verbose` as you will have a timestamp right above it for the last check before the password was updated.

- The ASCII art is currently printed each time the tool is run. If I continue development, I will likely add a `-nobanner` (or similar) switch to remove the ASCII art for conciseness and maximal "screenshotability."
