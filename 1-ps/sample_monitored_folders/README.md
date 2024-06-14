# PowerShell commands to manipulate the sample files
- Get the list of files in the current folder with file date/time attributes: 
```PowerShell
  Get-ChildItem -Path . -File | Where-Object {$_.CreationTime} | Sort-Object CreationTime -Descending| Select-Object -First 5 | Select Length, Name, LastWriteTime,CreationTime,LastAccessTime
 ```

- Change file creation time:
 ```PowerShell
 $(Get-Item .\file_03.test).CreationTime=$(Get-Date "07/31/2024")
 ```

- Change file last write time:
 ```PowerShell
 $(Get-Item .\file_03.test).LastWriteTime=$(Get-Date "07/31/2024") 
 ```

- Change file last access time:
 ```PowerShell
 $(Get-Item .\file_03.test).LastAccessTime=$(Get-Date "07/31/2024")
 ```