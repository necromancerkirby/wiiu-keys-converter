# Created by necromancerkirby
# Did this help you? Want to pay it forward? Either donate me a coffee XMR (Monero) 89EmNU7rvyWUdjNxBfgyrQ3SSwTfeNk7bSGhwMGz2oRBZfGcKePXxHkMpCmCmY8cc9DBacMCL47WNNYy884CRM6NGS1hjTB
# Or just keep sharing the script around to those who need help.

<#
.SYNOPSIS
Extracts the data from the provided Wii U Disc Keys and convert them to their string(text) representation.

.EXAMPLE
Specify the source path. If you dropped the script in the same folder where all keys resides you don't need to do this.
.\disc_keys_converter.ps1 -Url "download keys url"
This AutoConfirm will not prompt you for a yes or no on the source path specified.
.\disc_keys_converter.ps1 -AutoConfirm 1 -SkipDownload 1

If you have the keys, just create a temp folder and put them there. (temp folder must be in the same place as the script)

#>


[CmdletBinding()]
param (
    [Parameter(Mandatory = $false, HelpMessage = "Specify the path to your Wii U Disc Keys")]
    [string]
    $SourcePath,
    [Parameter(Mandatory = $false, HelpMessage = "Assume the path isn't the same path as the script's working directory")]
    [bool]
    $AssumeDifferentSourcePath = $true,
    [Parameter(Mandatory = $false, HelpMessage = "Skip Source Path prompt")]
    [bool]
    $AutoConfirm,
    [Parameter(Mandatory = $false, HelpMessage = "Skip download")]
    [bool]
    $SkipDownload,
    [Parameter(Mandatory = $false, HelpMessage = "Download URL")]
    [string]
    $Url
)

# global variables
$TempFolder = "temp";
$OSPathSeparator = [System.IO.Path]::DirectorySeparatorChar
$SourcePath = ($SourcePath) ? $SourcePath : $PWD
$ProgressPreference = "Continue"



if ( $AutoConfirm ) {
    Write-Host "Skipping Source Path confirmation" -ForegroundColor Green
}

if (Test-Path -Path "keys.txt") {
    $confirmation = Read-Host "A keys.txt file has been generated, do you wish to delete it?" 
    # ensure confirmation is either
    if (($null -eq $confirmation -or $confirmation -eq "") -or !($confirmation -imatch "^n|no|y|yes$")) {
        Write-Host "Answer shouldn't be empty. Only input accepted is [Y/Yes] for Yes or [N/No] for No" -ForegroundColor Red
        exit
    } 

    if ($confirmation -imatch "^y|yes$") {
        Remove-Item -Path "keys.txt" -Verbose
    }

}

if (!$Url -and !$SkipDownload) {
    Write-Host "Neither a URL or Skip Download flag have been set. "
    exit;
}

if ($AssumeDifferentSourcePath -and $AutoConfirm -ne $true) {
    
    Write-Host "The Source Path is set to: $($SourcePath)" -ForegroundColor Yellow 
    $confirmation = $null;
    try {
        
        $confirmation = Read-Host "Is this information correct? (Y/N)" 
    }
    catch {
        Write-Information "System interruption received." -InformationAction Continue
    }
    $confirmation = $confirmation.ToLower().Trim()
    # ensure confirmation is either
    if (($null -eq $confirmation -or $confirmation -eq "") -or !($confirmation -imatch "^n|no|y|yes$")) {
        Write-Host "Answer shouldn't be empty. Only input accepted is [Y/Yes] for Yes or [N/No] for No" -ForegroundColor Red
        exit
    } 
    if ($confirmation -imatch "^n|no$") {
        Write-Information "Start script again with the Source Path specified." -InformationAction Continue
        Write-Information "If you don't know how you can do the following after this message in powershell: Get-Help ./disc_keys_converter.ps1" -InformationAction Continue
        exit 0;
    }

}

Write-Host "Source Path (zip files containing keys): $($SourcePath)" -ForegroundColor Green
$TestPathExists = Test-Path ( -join ($SourcePath, $OSPathSeparator, $TempFolder))

if (!($TestPathExists)) {
    New-Item -ItemType Directory -Name $TempFolder
}

function DownloadItems {
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $Url,
        [Parameter()]
        [uint]
        $MaxDownload = 10,
        [Parameter()]
        [string]
        $FileExtension = "*.zip"
    )

    # put into a function with parameters
    $webpage = Invoke-WebRequest -Uri $Url # Replace with the URL of the website you want to download from
    $links = $webpage.Links | Where-Object { $_.href -like $FileExtension } # Replace with the file extensions you want to download
    $ItemsQueue = New-Object System.Collections.Queue;
    $JobsRunning = New-Object System.Collections.ArrayList;
    $CompletedJobsCleanup = New-Object System.Collections.ArrayList;

    foreach ($link in $links) {
        $ItemsQueue.Enqueue($link);
    }
    $TotalItems = $ItemsQueue.Count;
    $Progress = 0;
    $Downloaded = 0;
    Write-Progress -Activity "Downloading items" -PercentComplete $Progress

    while ($ItemsQueue.Count -gt 0) {

        #reset progress just in case script halted somewhere
        $ProgressPreference = "Continue"
        $Item = $ItemsQueue.Dequeue();

        if ($JobsRunning.Count -eq $MaxDownload) {
            Start-Sleep 5
        }

        if ($JobsRunning.Count -ne $MaxDownload -and !($jobs_running.Count -gt $MaxDownload)) {
        
            # start-job has too much of an overhead and requires spawning several powershell processes
            # using start-threadjob just spin a threadpool and it is much faster
            $job = Start-ThreadJob -ScriptBlock {
                param($Item, $Url, $TempFolder, $SourcePath, $OSPathSeparator)
                $FilenameDecoded = [System.Uri]::UnescapeDataString($Item.href);
                Write-Host "Downloading $($FilenameDecoded)..."
                $AbsoluteFilePath = Join-Path $SourcePath $OSPathSeparator $TempFolder $FilenameDecoded;
                $full_link = -join ($Url, $Item.href);
                $ProgressPreference = 'SilentlyContinue'
                Invoke-WebRequest -Uri $full_link -OutFile $AbsoluteFilePath 
                $ProgressPreference = 'Continue'
                Write-Host "Saved file in $($AbsoluteFilePath)"
            } -ArgumentList $Item, $Url, $TempFolder, $SourcePath, $OSPathSeparator -Verbose

            $JobsRunning.Add($job) > $null;
        }

        foreach ($jobStarted in $JobsRunning) {
            $output = Receive-Job $jobStarted;
            $_downloading = ""
            if ($output) {

                foreach ($line in $output) {
                    if ($line) {
                        $line = $line.Trim();

                        if ($line -and $line.ToLower().Contains("downloading")) {
                            $_downloading = $line;
                            #Write-Host $line -ForegroundColor Yellow
                        }
                        elseif ($line -and $line.ToLower().Contains("saved" )) {

                            Write-Host $line -ForegroundColor Green
                        }
                    }
                }

            }
            if ($jobStarted.State -eq "Completed") {
                $Downloaded += 1;
                Stop-Job $jobStarted
                $CompletedJobsCleanup.Add($jobStarted) > $null;
                $Progress = [Math]::Round(($Downloaded / $TotalItems) * 100);
                Write-Progress -Activity "[$($Downloaded)/$($TotalItems)] $($_downloading)" -PercentComplete $Progress 
            } 
        }

        foreach ($completed in $CompletedJobsCleanup) {
            $JobsRunning.Remove($completed)
        }
        $CompletedJobsCleanup.Clear()
    }

    Write-Host "Download complete" -ForegroundColor Yellow
}

Function ExpandZipFiles {

    param (
        [Parameter(Mandatory = $true)]
        [string]
        $TempFolder,
        [Parameter(Mandatory = $true)]
        [string]
        $DestinationPath
    )

    $zipFiles = Get-ChildItem -Path "$($TempFolder)/" -Filter "*.zip"

    $zipFiles | ForEach-Object {

        Expand-Archive -Path $_.FullName -DestinationPath "$($DestinationPath)" -Force

    }

}

Function HexToString {
    param (
        [Parameter(Mandatory)]
        [string]
        $TempFolder
    )

    $stringKeys = New-Object System.Collections.ArrayList
    $keyList = Get-ChildItem -Path "$($TempFolder)/" -Filter "*.key"
    
    $keyList | ForEach-Object {
        $keyBytes = [System.IO.File]::ReadAllBytes($_.FullName);
        $keyBytesAscii = $keyBytes | ForEach-Object { $_.ToString("X2"); }
        $keyBytesAscii = $keyBytesAscii -join ""
        $GameName = $_.Name -replace ".key", ""
        $keyBytesAscii = -join ($keyBytesAscii, " # $($GameName)")
        $stringKeys.Add($keyBytesAscii) > $null
    }

    return $stringKeys;

}

if (!$SkipDownload) {

    DownloadItems -Url  $Url;

}
Write-Host "Extracting all keys..." 
ExpandZipFiles -TempFolder $TempFolder -DestinationPath "$($TempFolder)/"
Write-Host "Extraction complete" -ForegroundColor Green
Write-Host "Converting all keys and outputting them to keys.txt" -ForegroundColor Green
$data = HexToString -TempFolder $TempFolder
$data | ForEach-Object { ($_.ToString() -join [System.Environment]::NewLine) | Out-File -FilePath "keys.txt" -Append }
Write-Host "Done. If all went well you should have your keys.txt autogenerated" -ForegroundColor Green