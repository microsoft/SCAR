function Start-DscBuild
{
    <#
    .SYNOPSIS
    Executes DSCSM functions that compile dynamic configurations for each machine based on the parameters and
    parameter values provided within that VM's configuration data.

    .PARAMETER Rootpath
    Path to the root of the DSCSM repository/codebase.

    .PARAMETER ValidateModules
    Executes the Copy-DscModules cmdlet and sync modules/versions with what is in the "5. resouces\Modules" folder of
    DSCSM.

    .PARAMETER ArchiveFiles
    Switch parameter that archives the artifacts produced by DSCSM. This switch compresses the artifacts and
    places them in the archive folder.

    .PARAMETER CleanBuild
    Switch parameter that removes files from the MOFs and Artifacts folders to create a clean slate for the DSCSM build.

    .PARAMETER CleanArchive
    Switch Parameter that r$dscdataemoves files from the archive folder.

    .PARAMETER NodeDataFiles
    Allows users to provide an array of configdata files to target outside of the Nodedata folder.

    .PARAMETER PreRequisites
    Executes nodededata generation, DSC module copy, and WinRM configuration as part of the DSCSM build process.

    .EXAMPLE
    Start-DscBuild -RootPath "C:\DSC Management" -CleanBuild -CleanArchive -PreRequisites

    #>

    [cmdletbinding()]
    param(

        [Parameter()]
        [string]
        $RootPath = (Get-Location).Path,

        [Parameter()]
        [string]
        $TargetFolder,

        [Parameter()]
        [switch]
        $CopyModules,

        [Parameter()]
        [switch]
        $ArchiveFiles,

        [Parameter()]
        [switch]
        $CleanBuild,

        [Parameter()]
        [array]
        $NodeDataFiles,

        [Parameter()]
        [switch]
        $PreRequisites
    )

    # Root Folder Paths
    $nodeDataPath    = (Resolve-Path -Path "$RootPath\*NodeData").Path
    $dscConfigPath   = (Resolve-Path -Path "$RootPath\*Configurations").Path
    $resourcePath    = (Resolve-Path -Path "$RootPath\*Resources").Path
    $artifactPath    = (Resolve-Path -Path "$RootPath\*Artifacts").Path
    $reportsPath     = (Resolve-Path -Path "$RootPath\*Artifacts\Reports").Path
    $mofPath         = (Resolve-Path -Path "$RootPath\*Artifacts\Mofs").Path

    # Begin Build
    Write-Output "Beginning Desired State Configuration Build Process`r`n"

    # Remove old Mofs/Artifacts
    if ($CleanBuild)
    {
        Remove-BuildItems -RootPath $RootPath
    }

    # Validate Modules on host and target machines
    if ($CopyModules)
    {
        Copy-DSCModules -Rootpath $RootPath
    }

    # Import required DSC Resource Modules
    #Import-DscModules -ModulePath "$ResourcePath\Modules"

    # Combine PSD1 Files
    $allNodesDataFile = "$artifactPath\DscConfigs\AllNodes.psd1"

    if ($null -eq $NodeDataFiles)
    {
        if ('' -eq $TargetFolder)
        {
            [array]$NodeDataFiles = Get-ChildItem -Path "$nodeDataPath\*.psd1" -Recurse | Where-Object { ($_.Fullname -notmatch "Staging") -and ($_.Fullname -Notlike "Readme*")}
            Get-CombinedConfigs -RootPath $RootPath -AllNodesDataFile $allNodesDataFile -NodeDataFiles $NodeDataFiles
            Export-DynamicConfigs -NodeDataFiles $NodeDataFiles -ArtifactPath $artifactPath -DscConfigPath $dscConfigPath
            Export-Mofs -RootPath $RootPath
        }
        else
        {
            [array]$NodeDataFiles = Get-ChildItem -Path "$nodeDataPath\$TargetFolder\*.psd1" -Recurse | Where-Object { ($_.Fullname -notmatch "Staging") -and ($_.Fullname -Notlike "Readme*")}
            Get-CombinedConfigs -RootPath $RootPath -AllNodesDataFile $allNodesDataFile -NodeDataFiles $NodeDataFiles -TargetFolder $TargetFolder
            Export-DynamicConfigs -NodeDataFiles $NodeDataFiles -ArtifactPath $artifactPath -DscConfigPath $dscConfigPath -TargetFolder $TargetFolder
            Export-Mofs -RootPath $RootPath -TargetFolder $TargetFolder
        }
    }

    # Archive generated artifacts
    if ($archiveFiles)
    {
        Compress-DscArtifacts -Rootpath $RootPath
    }

    # DSC Build Complete
    Write-Output "`n`n`t`tDesired State Configuration Build complete.`n`n"
}

function Get-CombinedConfigs
{
    <#

    .SYNOPSIS
    Generates configuration data for each node defined within a targetted folder and generates a single .psd1 for each node with
    their combined "AppliedConfigurations" and parameters to generate MOFs off of. Also generates a single configuration data file
    containing all nodes/configurations.

    .PARAMETER RootPath
    Path to the Root of the DSCSM platforms

    .EXAMPLE
    Get-CombinedConfigs -RootPath "C:\DSCSM"

    #>

    [cmdletBinding()]
    param (

        [Parameter()]
        [string]
        $RootPath = (Get-Location).Path,

        [Parameter()]
        [string]
        $AllNodesDataFile,

        [Parameter()]
        [array]
        $TargetFolder,

        [Parameter()]
        [array]
        $NodeDataFiles

    )

    if ($null -eq $NodeDataFiles)
    {
        $nodeDataPath = (Resolve-Path -Path "$Rootpath\*NodeData").Path
        if ('' -ne $targetFolder)
        {
            [array]$allConfigFiles = Get-ChildItem -Path "$NodeDataPath\*.psd1" -Recurse | Where-Object { ($_.Fullname -notmatch "Staging") -and ($_.Fullname -Notlike "Readme*") }
        }
        else
        {
            [array]$allConfigFiles = Get-ChildItem -Path "$NodeDataPath\$TargetFolder\*.psd1" -Recurse | Where-Object { ($_.Fullname -notmatch "Staging") -and ($_.Fullname -Notlike "Readme*") }
        }
    }

    foreach ($configFile in $allConfigFiles)
    {
        $data = Invoke-Expression (Get-Content $nodeConfig.FullName | Out-String)

        if ($null -ne $data.AppliedConfigurations)
        {
            $nodeDataFiles += $configFile
        }
    }

    if ($nodeDataFiles.count -lt 1)
    {
        Write-Output "No DSC configdata files were provided."
    }
    else
    {
        Write-Output "`n`tBeginning Powershell Data File build for $($NodeDataFiles.count) Targetted Machines.`n"
        New-Item -Path $AllNodesDataFile -ItemType File -Force | Out-Null
        $string = "@{`n`tAllNodes = @(`n"
        $string | Out-File $AllNodesDataFile -Encoding utf8
        [int]$countOfConfigurations = ($NodeDataFiles | Measure-object | Select-Object -expandproperty count)
        for ($i = 0; $i -lt $countOfConfigurations; $i++)
        {
            Get-Content -Path $($NodeDataFiles[$i].FullName) -Encoding UTF8 |
            ForEach-Object -Process {
                "`t`t" + $_ | Out-file $AllNodesDataFile -Append -Encoding utf8
            }

            if ($i -ne ($countOfConfigurations - 1) -and ($countOfConfigurations -ne 1))
            {
                "`t`t," | Out-file $allNodesDataFile -Append -Encoding utf8
            }
        }
        "`t)`n}" | Out-File $allNodesDataFile -Append -Encoding utf8
    }
}

function Export-DynamicConfigs
{
    <#

    .SYNOPSIS
    Generates DSC scripts with combined parameter and parameter values based on
    provided configuration data.

    .PARAMETER NodeDataFiles
    Array of configuration data files. Targets all .psd1 files under the "NodeData" folder
    that are not located in the staging folder.
    Example -NodeDataFiles $ConfigDataArray

    .PARAMETER ArtifactPath
    Path to the Artifacts Folder. Defaults to the "4. Artifacts" folder from the Rootpath provided by
    the Start-DscBuild function.

    .EXAMPLE
    Export-DynamicConfigs -NodeDataFiles $NodeDataFiles -ArtifactPath $artifactPath

    #>

    [cmdletBinding()]
    param (

        [Parameter()]
        [array]
        $NodeDataFiles,

        [Parameter()]
        [string]
        $TargetFolder,

        [Parameter()]
        [string]
        $ArtifactPath,

        [Parameter()]
        [string]
        $DscConfigPath
    )

    $jobs = @()
    foreach ($NodeDataFile in $NodeDataFiles)
    {
        $machinename = $NodeDataFile.basename
        if ('' -ne $TargetFolder -and $NodeDataFile.fullname -notlike "*\$TargetFolder\*")
        {
            Continue
        }
        else
        {
            Write-Output "`t`tStarting Job - Compile DSC Configuration for $($nodedatafile.basename)"

            $job = Start-Job -Scriptblock {
                $nodeDataFile       = $using:nodeDataFile
                $dscConfigPath      = $using:dscConfigPath
                $artifactPath       = $using:ArtifactPath
                $machinename        = $using:machinename
                $nodeConfigScript   = "$ArtifactPath\DscConfigs\$machineName.ps1"
                $data               = Invoke-Expression (Get-Content $NodeDataFile.FullName | Out-String)

                if ($null -ne $data.AppliedConfigurations)
                {
                    $appliedConfigs     = $data.appliedconfigurations.Keys
                    $lcmConfig          = $data.LocalConfigurationManager.Keys
                    $nodeName           = $data.NodeName
                    Write-Output "`t$machineName - Building Customized Configuration Data`n"
                    New-Item -ItemType File -Path $nodeConfigScript -Force | Out-Null

                    foreach ($appliedConfig in $appliedConfigs)
                    {

                        if (Test-Path $NodeDataFile.fullname)
                        {
                            Write-Output "`t`tConfigData Import - $appliedConfig"

                            $dscConfigScript = "$DscConfigPath\$appliedConfig.ps1"
                            $fileContent = Get-Content -Path $dscConfigScript -Encoding UTF8 -ErrorAction Stop
                            $fileContent | Out-file $nodeConfigScript -Append -Encoding utf8 -ErrorAction Stop
                            . $dscConfigScript
                            Invoke-Expression ($fileContent | Out-String) #DevSkim: ignore DS104456
                        }
                        else
                        {
                            Throw "The configuration $appliedConfig was specified in the $($NodeDataFile.fullname) file but no configuration file with the name $appliedConfig was found in the \Configurations folder."
                        }
                    }

                    $mainConfig = "Configuration MainConfig`n{`n`tNode `$AllNodes.Where{`$_.NodeName -eq `"$nodeName`"}.NodeName`n`t{"

                    foreach ($appliedConfig in $appliedConfigs)
                    {
                        Write-Output "`t`tParameter Import - $AppliedConfig"

                        $syntax                     = Get-Command $appliedConfig -Syntax -ErrorAction Stop
                        $appliedConfigParameters    = [Regex]::Matches($syntax, "\[{1,2}\-[a-zA-Z0-9]+") |
                        Select-Object @{l = "Name"; e = { $_.Value.Substring($_.Value.IndexOf('-') + 1) } },
                        @{l = "Mandatory"; e = { if ($_.Value.IndexOf('-') -eq 1) { $true }else { $false } } }
                        $mainConfig += "`n`t`t$appliedConfig $appliedConfig`n`t`t{`n"

                        foreach ($appliedConfigParameter in $appliedConfigParameters)
                        {
                            if ($null -ne $data.appliedconfigurations.$appliedConfig[$appliedConfigParameter.name])
                            {
                                $mainConfig += "`t`t`t$($appliedConfigParameter.name) = `$node.appliedconfigurations.$appliedConfig[`"$($appliedConfigParameter.name)`"]`n"
                            }
                            elseif ($true -eq $appliedConfigParameter.mandatory)
                            {
                                $errorMessage = "$nodeName configuration $appliedConfig has a mandatory parameter $($appliedConfigParameter.name) and was not specified.`n`n"
                                $errorMessage += "$appliedConfig = @{`n"
                                foreach ($appliedConfigParameter in $appliedConfigParameters)
                                {
                                    $errorMessage += "`t$($appliedconfigParameter.name) = `"VALUE`"`n"
                                }
                                $errorMessage += "}"
                                Throw $errorMessage
                            }
                        }
                        $mainConfig += "`t`t}`n"
                    }
                    $mainConfig += "`t}`n}`n"
                    $mainConfig | Out-file $nodeConfigScript -Append -Encoding utf8
                    #endregion Build configurations and generate MOFs

                    #region Generate data for meta.mof (Local Configuration Manager)

                    if ($null -ne $lcmConfig)
                    {
                        Write-Output "`t`tGenerating LCM Configuration"
                        [array]$lcmParameters = "ActionAfterReboot", "AllowModuleOverWrite", "CertificateID", "ConfigurationDownloadManagers", "ConfigurationID", "ConfigurationMode", "ConfigurationModeFrequencyMins", "DebugMode", "StatusRetentionTimeInDays", "SignatureValidationPolicy", "SignatureValidations", "MaximumDownloadSizeMB", "PartialConfigurations", "RebootNodeIfNeeded", "RefreshFrequencyMins", "RefreshMode", "ReportManagers", "ResourceModuleManagers"
                        $localConfig = "[DscLocalConfigurationManager()]`n"
                        $localConfig += "Configuration LocalConfigurationManager`n{`n`tNode `$AllNodes.Where{`$_.NodeName -eq `"$nodeName`"}.NodeName`n`t{`n`t`tSettings {`n"

                        foreach ($setting in $lcmConfig)
                        {
                            if ($null -ne ($lcmParameters | Where-Object { $setting -match $_ }))
                            {
                                $localConfig += "`t`t`t$setting = `$Node.LocalconfigurationManager.$Setting`n"
                            }
                            else
                            {
                                Write-Warning "The term `"$setting`" is not a configurable setting within the Local Configuration Manager."
                            }
                        }
                        $localConfig += "`t`t}`n`t}`n}"
                        $localConfig | Out-file $nodeConfigScript -Append -Encoding utf8
                    }
                    Write-Output "`n`t$nodeName configuration file successfully generated.`r`n"
                }
            }
        }
        $jobs += $job.Id
    }
    Write-Output "`n`tJob Creation complete. Waiting for $($jobs.count) Jobs to finish processing. Output from Jobs will be displayed below once complete.`n`n"
    Get-Job -ID $jobs | Wait-Job | Receive-Job
}

function Export-Mofs
{
    <#

    .SYNOPSIS

    .PARAMETER Rootpath
    Path to the root of the DSCSM repository/codebase.

    .EXAMPLE
    Export-Mofs -RootPath "C:\DSCSM"

    #>

    [cmdletbinding()]
    param(

        [Parameter()]
        [string]
        $RootPath = (Get-Location).Path,

        [Parameter()]
        [string]
        $TargetFolder,

        [Parameter()]
        [array]
        $NodeDataFiles

    )

    $mofPath            = (Resolve-Path -Path "$RootPath\*Artifacts\Mofs").Path
    $dscConfigPath      = (Resolve-Path -Path "$RootPath\*Artifacts\DscConfigs").Path
    $allNodesDataFile   = (Resolve-Path -Path "$dscConfigPath\Allnodes.psd1").path
    $dscNodeConfigs     = @()
    $jobs               = @()

    if ($NodeDataFiles.count -lt 1)
    {
        if ('' -ne $TargetFolder)
        {
            $nodeDataFiles = Get-Childitem "$RootPath\NodeData\$TargetFolder\*.psd1" -recurs
        }
        else
        {
            $nodeDataFiles = Get-Childitem "$RootPath\NodeData\*.psd1" -Recurse
        }
    }

    foreach ($file in $nodeDataFiles)
    {

        $basename = $file.basename
        if (Test-Path "$dscConfigPath\$basename.ps1")
        {
            $dscNodeConfigs += Get-Item -path "$dscConfigPath\$basename.ps1" -erroraction SilentlyContinue
        }
        else
        {
            Write-Warning "No DSC Configuration script exists for $basename."
            continue
        }
    }
    Write-Output "`tGenerating MOFs and Meta MOFs from compiled DSC Configuration Data.`n"

    foreach ($nodeConfig in $DscNodeConfigs)
    {
        Write-Output "`t`tStarting MOF Export Job for $($nodeConfig.BaseName)"
        $nodeName       = $nodeConfig.BaseName
        $configPath     = $nodeConfig.FullName
        $allNodesPath   = $allNodesDataFile.FullName
        $nodeDatafile   = (Resolve-Path -Path "$Rootpath\Nodedata\*\$nodeName.psd1").Path
        $data           = Invoke-Expression (Get-Content $NodeDataFile | Out-String)
        #[scriptblock]$nodeConfigContent = Get-Content $nodeConfig
        if ($null -ne $data.AppliedConfigurations)
        {
            try
            {
                Write-Output "`t`tStarting Job - Generate MOF and Meta MOF for $nodeName"

                $job = Start-Job -Scriptblock {

                    $nodeConfig         = $using:nodeConfig
                    $nodeName           = $using:nodeName
                    $allNodesDataFile   = $using:allNodesDataFile
                    $mofPath            = $using:mofPath
                    $configPath         = $using:ConfigPath

                    # Execute each file into memory
                    . "$configPath"

                    # Execute each configuration with the corresponding data file
                    Write-Output "`t`tGenerating MOF for $nodeName"
                    $null = MainConfig -ConfigurationData $allNodesDataFIle -OutputPath $mofPath -ErrorAction Stop 3> $null

                    # Execute each Meta Configuration with the corresponding data file
                    Write-Output "`t`tGenerating Meta MOF for $nodeName"
                    $null = LocalConfigurationManager -ConfigurationData $allNodesDataFile -Outputpath $mofPath -Erroraction Stop 3> $null
                }
                $jobs += $job.id
            }
            catch
            {
                Throw "Error occured executing $nodeDataFile to generate MOF.`n $($_)"
            }
        }
    }
    Write-Output "`n`tMOF Export Job Creation Complete. Waiting for $($jobs.count) to finish processing. Output from Jobs will be displayed below once complete.`n"
    Get-Job -ID $jobs | Wait-Job | Receive-Job
}



function Remove-BuildItems
{
    <#

    .SYNOPSIS
    Removes artifacts generated by a DSCSM build from the MOFs and Artifacts folders. If the -CleanArchive switch is
    provided, all artifacts within the archive folder will also be removed.

    .PARAMETER Rootpath
    Path to the root of the DSCSM repository/codebase.

    .PARAMETER CleanArchive
    Switch parameter that removes items from the Archive folder.

    .EXAMPLE
    Remove-BuildItems -Rootpath "C\DSCSM" -CleanArchive

    #>

    [cmdletBinding()]
    param (

        [Parameter()]
        [string]
        $RootPath = (Get-Location).Path,

        [Parameter()]
        [switch]
        $CleanArchive
    )

    $mofPath        = Resolve-Path "$RootPath\*Artifacts\*Mofs\"
    $artifactPath   = Resolve-Path "$RootPath\*Artifacts"
    $removeItems    = Get-Childitem "$MofPath\*.mof" -Recurse
    $removeItems    += Get-Childitem "$ArtifactPath\*.ps*" -Recurse

    Write-Output "`n`tBUILD: Removing Existing Mofs and build artifacts."

    foreach ($item in $removeItems)
    {
        Write-Output "Removing $($item.Name)"
        Remove-Item $item.Fullname -Confirm:$false -ErrorAction SilentlyContinue
    }
    Write-Output "`r`n"
}

function Import-DscModules
{
    <#

    .SYNOPSIS
    Imports the required modules stored in the "Resources\Modules" folder on the local system.

    .PARAMETER Rootpath
    Path to the root of the DSCSM repository/codebase.

    .EXAMPLE
    Import-DscModules -ModulePath "$RootPath\Resouces\Modules"

    #>

    [cmdletbinding()]
    param(

        [Parameter()]
        [String]
        $ModulePath

    )

    $modules = @(Get-ChildItem -Path $ModulePath -Directory -Depth 0)
    Write-Output "`n`tBUILD: Importing required modules onto the local system."

    foreach ($module in $modules)
    {
        Write-Output "`t`tImporting Module - $($module.name)."
        $null = Import-Module $Module.name -Force
    }

    $null = Set-PowerCLIConfiguration -Scope AllUsers -ParticipateInCEIP $false -Confirm:$false
    Write-Output "`n"
}

function Compress-DscArtifacts
{
    <#

    .SYNOPSIS
    Compresses the configuration scripts and MOFs generated by DSCSM and stores them in the Archive folder

    .PARAMETER RootPath
    Path to the root of the DSCSM repository/codebase.

    .EXAMPLE


    #>

    [cmdletbinding()]
    param(

        [Parameter()]
        [String]
        $RootPath = (Get-Location).Path

    )

    # Archive the current MOF and build files in MMddyyyy_HHmm_DSC folder format
    $artifactPath   = (Resolve-Path -Path "$Rootpath\*Artifacts").Path
    $archivePath    = (Resolve-Path -Path "$Rootpath\*Archive").Path
    $datePath       = (Get-Date -format "MMddyyyy_HHmm")

    Compress-Archive -Path $artifactPath -DestinationPath ("$archivePath\{0}_DSC.zip" -f $datePath) -Update
}

function Set-WinRM
{
    <#

    .SYNOPSIS
    This function will validate that the WinRM Service is running on target machines, that the MaxEnevelopeSize is set to 10000, and has a switch parameter to include the staging directory.

    .PARAMETER Rootpath
    Path to the root of the DSCSM repository/codebase.

    .PARAMETER MaxEnevelopeSize
    MaxEnevelopeSize is a configuration setting in WinRM. DSCSM requires this setting to be at (10000). This parameter allows you to set it to any number which easily allows you to reset WinRM to the default value (500).
    The default setting of this parameter is set to 10000.

    .PARAMETER IncludeStaging
    Switch Parameter that also includes the target machines in the Staging directory under 1.\Node Data

    .EXAMPLE
    Example Set-WinRM -RootPath "C:\Your Repo\SCAR"
        In this example, the target machines (not including staging) would be validated that WinRM is running and the value of MaxEnvelopeSize is set to 10000. If it is set to a number other than 10000, it would be modified to match 10000.

    Example Set-WinRM -RootPath "C:\Your Repo\SCAR" -MaxEnvelopeSize "500"
        In this example, the target machines (not including staging) would be validated that WinRM is running and the value of MaxEnvelopeSize is set to 500. If it is set to a number other than 500, it would be modified to match 500.

    Example Set-WinRM -RootPath "C:\Your Repo\SCAR" -MaxEnvelopeSize "500" -IncludeStaging
        In this example, the target machines (including staging) would be validated that WinRM is running and the value of MaxEnvelopeSize is set to 500. If it is set to a number other than 500, it would be modified to match 500.

    #>

    [cmdletbinding()]
    param(

        [Parameter()]
        [array]
        $RootPath = (Get-Location).Path,

        [Parameter()]
        [string]
        $MaxEnvelopeSize = "10000",

        [Parameter()]
        [switch]
        $IncludeStaging,

        [Parameter()]
        [array]
        $TargetMachines

    )

    $nodeDataPath = (Resolve-Path -Path "$RootPath\NodeData").Path
    $jobs = @()

    if ($null -eq $TargetMachines)
    {
        $TargetMachines = (Get-Childitem -Path $nodeDataPath -recurse | Where-Object { $_.FullName -like "*.psd1" -and $_.fullname -notlike "*staging*" }).basename
    }

    Write-Output "`tBUILD: Performing WinRM Validation and configuration."

    if ($IncludeStaging)
    {
        $TargetMachines += (Get-ChildItem -Path $nodeDataPath -recurse | Where-Object { $_.FullName -like "*.psd1" }).basename
    }

    foreach ($machine in $TargetMachines)
    {
        # Test for whether WinRM is enabled or not
        Write-Output "`t`tStarting Job - Configure WinRM MaxEnvelopeSizeKB on $machine"

        $job = Start-Job -Scriptblock {
            $machine                = $using:machine
            $RootPath               = $using:rootPath
            $MaxEnvelopeSize        = $using:MaxEnvelopeSize
            $currentMachineCount    += 1

            try
            {
                $remoteEnvelopeSize = Invoke-Command $machine -ErrorAction Stop -Scriptblock {
                    Return (Get-Item -Path WSMan:\localhost\MaxEnvelopeSizeKb).value
                }
            }
            catch
            {
                Write-Warning "`t`tUnable to connect to $machine. Ensure WinRM access is enabled."
                Continue
            }

            if ($MaxEnvelopeSize -eq $remoteEnvelopeSize)
            {
                Write-Output "`t`tCurrent MaxEnvelopSize size for $machine matches Desired State"
                Continue
            }
            else
            {
                Write-Output "`t`tCurrent MaxEnvelopSizeKB for $machine is $remoteEnvelopeSize. Updating to $MaxEnvelopeSize"

                try
                {
                    $remoteEnvelopeSize = Invoke-Command $machine -ErrorAction Stop -ArgumentList $MaxEnvelopeSize -Scriptblock {
                        param ($RemoteMaxEnvelopeSize)
                        $machineEnvSize = (Get-Item -Path WSMan:\localhost\MaxEnvelopeSizeKb).value
                        if ($machineEnvSize -ne $RemoteMaxEnvelopeSize)
                        {
                            Set-Item -Path WSMan:\localhost\MaxEnvelopeSizeKb -Value $RemoteMaxEnvelopeSize
                        }
                        return (Get-Item -Path WSMan:\localhost\MaxEnvelopeSizeKb).value
                    }
                }
                catch
                {
                    Write-Warning "Unable to set MaxEnvelopSize on $machine."
                    continue
                }
            }
        }
        [array]$jobs += $job.ID
    }
    Get-Job -ID $jobs | Wait-Job | Receive-Job
    Write-Output "`tBUILD: WinRM Validation Complete.`n"
}

function Copy-DSCModules
{
    <#

    .SYNOPSIS
    This function validates the modules on the target machines. If the modules are not preset or are the incorrect version, the function will copy them to the target machines.

    .PARAMETER TargetMachines
    List of target machines. If not specificied, a list will be generated from configurations present in "C:\Your Repo\SCAR\NodeData"

    .PARAMETER Rootpath
    Path to the root of the DSCSM repository/codebase.

    .EXAMPLE
    Example Copy-DSCModules -rootpath "C:\Repos\DSCSM"

    #>

    [cmdletbinding()]
    param(

        [Parameter()]
        [array]
        $TargetMachines,

        [Parameter()]
        [string]
        $RootPath = (Get-Location).Path,

        [Parameter()]
        [switch]
        $LocalHost,

        [Parameter()]
        [switch]
        $Force

    )
    $ModulePath = "$RootPath\Resources\Modules"
    $nodeDataPath = "$RootPath\NodeData"
    $jobs = @()

    if ($LocalHost)
    {
        $TargetMachines = "LocalHost"
    }
    elseif ($TargetMachines.count -lt 1)
    {
        $targetMachines = @(Get-ChildItem -Path "$nodeDataPath\*.psd1" -Recurse | Where-Object { ($_.Fullname -notmatch "Staging") -and ($_.Fullname -Notlike "Readme*") }).basename
    }

    Write-Output "`n`tBUILD: Performing DSC Module Validation."

    foreach ($machine in $TargetMachines)
    {
        Write-Output "`t`tStarting Job - Syncing DSC Modules on $machine."
        
        $job = Start-Job -Scriptblock {
            $machine                = $using:machine
            $RootPath               = $using:RootPath
            $ModulePath             = $using:ModulePath
            $Force                  = $using:Force
            $currentMachineCount    += 1
            
            if ($machine -eq 'localhost' -or $machine -eq $env:ComputerName)
            {
                $destinationPath = "C:\Program Files\WindowsPowershell\Modules"
                $destinationModulePaths = @(
                    "C:\Program Files\WindowsPowershell\Modules"
                    "C:\Program Files(x86)\WindowsPowershell\Modules"
                    "C:\Windows\System32\WindowsPowershell\1.0\Modules"
                )
            }
            else
            {
                $destinationPath = "\\$Machine\C$\Program Files\WindowsPowershell\Modules"
                $destinationModulePaths = @(
                    "\\$Machine\C$\Program Files\WindowsPowershell\Modules"
                    "\\$Machine\C$\Program Files(x86)\WindowsPowershell\Modules"
                    "\\$Machine\C$\Windows\System32\WindowsPowershell\1.0\Modules"
                )
            }
            $modulePathTest         = Test-Path $ModulePath -ErrorAction SilentlyContinue
            $destinationPathTest    = Test-Path $destinationPath -ErrorAction SilentlyContinue

            if ($destinationPathTest -and $modulePathTest)
            {
                $modules = Get-Childitem -Path $modulePath -Directory -Depth 0 | Where-Object { $_.Name -ne "DSCEA" -and $_.name -ne "Pester" }

                foreach ($module in $modules)
                {

                    Write-Output "`t`Validating $($Module.Name) on $machine."

                    [int]$completedChecks = 0
                    $moduleVersion = (Get-ChildItem -Path $Module.Fullname -Directory -Depth 0).name

                    foreach ($destinationModulePath in $destinationModulePaths)
                    {
                        $modulecheck = Test-Path "$destinationPath\$($Module.name)" -ErrorAction SilentlyContinue

                        if ($force -and $moduleCheck)
                        {
                            $null = Remove-Item "$destinationModulePath\$($module.name)" -Confirm:$false -Recurse -Force -erroraction SilentlyContinue
                            $copymodule = $true
                            continue
                        }
                        else
                        {
                            if ($moduleCheck)
                            {
                                $versionCheck = Test-Path "$destinationPath\$($Module.name)\$moduleVersion" -ErrorAction SilentlyContinue
                            }
                            else
                            {
                                $completedChecks += 1
                            }

                            if ($modulecheck -and $versioncheck)
                            {
                                $copyModule = $false
                            }
                            elseif ($True -eq $moduleCheck -and ($false -eq $versionCheck))
                            {
                                $destinationVersion = Get-Childitem "$destinationPath\$($Module.name)" -Depth 0
                                Write-Output "`t`t$($Module.name) found with version mismatch."
                                Write-Output "`t`tRequired verion - $moduleVersion."
                                Write-Output "`t`tInstalled version - $destinationVersion."
                                Write-Output "`t`tRemoving $($Module.name) from $machine."
                                $null = Remove-Item "$destinationModulePath\$($module.name)" -Confirm:$false -Recurse -Force -ErrorAction SilentlyContinue
                                $copyModule = $true
                            }
                        }
                    }

                    if ($completedChecks -ge 3)
                    {
                        $copyModule = $true
                    }
                
                    if ($copyModule)
                    {
                        Write-Output "`t`tTransfering $($Module.name) to $Machine."
                        $null = Copy-Item -Path $Module.Fullname -Destination $destinationPath -Container -Recurse -force -erroraction SilentlyContinue
                        $moduleChanges = $true
                    }
                }
            }
            else
            {
                Write-Output "`t`tThere was an issue connecting to $machine to transfer the required modules."
                Continue
            }
        }
        [array]$jobs += $job.ID
    }
    Get-Job -ID $jobs| Wait-Job | Receive-Job
    Write-Output "`tModule Validation Complete.`n"
}

function Complete-Prereqs
{
    <#

    .SYNOPSIS
    The Complete-Prereqs function compiles and executes 3 other functions to complete the prereqruisites required for the DSCSM Build to complete.
    The function creates the configuration data for the target machines, validates the required DSC modules and copies the modules if they are not
    present on the target machine or if the modules present are not the latest version, and finally it validates that WinRM is enabled and set to
    the correct MaxEnevelopeSize as is required by DSCSM.

    .PARAMETER Rootpath
    Path to the root of the DSCSM repository/codebase.

    .PARAMETER SearchBase
    SearchBase should be set to the Security Group where your target machines are located.
    -SearchBase "CN=DSCSM Target Machines,OU=_Domain Administration,DC=corp,DC=contoso,DC=com"

    .PARAMETER DomainName
    DomainName should be set to the domain name of your domain.
    Example -DomainName "corp.contoso"

    .PARAMETER ForestName
    ForestName should be set to the forest name of your domain.
    Example -ForestName "com"

    .EXAMPLE
    complete-prereqs -rootpath "C:\Your Repo\SCAR" -searchbase "CN=DSCSM Target Machines,OU=_Domain Administration,DC=corp,DC=contoso,DC=com" -domainname "corp.contoso" -forestname "com"

    #>

    [cmdletbinding()]
    param(

        [Parameter()]
        [string]
        $RootPath = (Get-Location).Path,

        [Parameter()]
        [string]
        $SearchBase

    )

    New-ConfigData  -SearchBase $SearchBase
    Copy-DscModules -RootPath $RootPath
    Set-WinRM       -Rootpath $RootPath -IncludeStaging
}

function New-ConfigData
{

    <#

    .SYNOPSIS
    Generates configuration data based on a provided Organizational Unit
    DistinguishedName searchbase.

    .PARAMETER SearchBase
    Distringuised Name of the Active Directory Security Group you want to target for Node Data generation.
    Example -searchbase "CN=DSCSM Target Machines,OU=_Domain Administration,DC=corp,DC=contoso,DC=com"

    .PARAMETER NodeDataPath
    Path to the DSCSM Node Data folder.
    Example -NodeDataPath "C:\DSCSM\NodeData"

    .PARAMETER DomainName
    DomainName should be set to the domain name of your domain. Defaults to local system's Domain.
    Example -DomainName "corp.contoso"

    .PARAMETER ForestName
    ForestName should be set to the forest name of your domain. Defaults to local system's Forest.
    Example -ForestName "com"

    .EXAMPLE
    New-ConfigData -Rootpath "C:\DSCSM" -SearchBase "CN=Servers,CN=Enterprise Management,DC=contoso,DC=com"

    #>

    [cmdletbinding()]
    param(

        [Parameter()]
        [string]
        $SearchBase,

        [Parameter()]
        [switch]
        $LocalHost,

        [Parameter()]
        [switch]
        $RootOrgUnit,

        [Parameter()]
        [array]
        $ComputerName,

        [Parameter()]
        [string]
        [ValidateSet("MemberServers","AllServers","Full")]
        $Scope = "MemberServers",

        [Parameter()]
        [string]
        $RootPath = (Get-Location).path,

        [Parameter()]
        [hashtable]
        $LcmSettings = @{
            actionAfterReboot              = ""
            agentId                        = ""
            allowModuleOverwrite           = $True
            certificateID                  = ""
            configurationDownloadManagers  = ""
            configurationID                = ""
            configurationMode              = "ApplyAndAutoCorrect"
            configurationModeFrequencyMins = "15"
            credential                     = ""
            debugMode                      = ""
            downloadManagerCustomData      = ""
            downloadManagerName            = ""
            lcmStateDetail                 = ""
            maximumDownloadSizeMB          = "500"
            partialConfigurations          = ""
            rebootNodeIfNeeded             = $False
            refreshFrequencyMins           = "30"
            refreshMode                    = "PUSH"
            reportManagers                 = "{}"
            resourceModuleManagers         = "{}"
            signatureValidationPolicy      = ""
            signatureValidations           = "{}"
            statusRetentionTimeInDays      = "10"
        }
    )

    $NodeDataPath       = (Resolve-Path -Path "$RootPath\*NodeData").Path
    $targetMachineOus   = @()
    $targetMachines     = @()
    $jobs               = @()

        Write-Output "`tBeginning DSC Configuration Data Build - Identifying Target Systems."

        if ('' -ne $SearchBase)             {$Scope -eq "OrgUnit"}
        elseif ($LocalHost)                 {$Scope -eq "Local"}
        elseif ($ComputerName.count -gt 0)  {$Scope = "Targeted"}

        switch ($Scope)
        {
            "OrgUnit"       {[array]$targetMachines = @(Get-ADComputer -SearchBase $SearchBase -Filter * -Properties "operatingsystem", "distinguishedname")}
            "MemberServers" {[array]$targetMachines = @(Get-ADComputer -Filter {OperatingSystem -like "**server*"} -Properties "operatingsystem", "distinguishedname" | Where-Object {$_.DistinguishedName -Notlike "*Domain Controllers*"})}
            "AllServers"    {[array]$targetMachines = @(Get-ADComputer -Filter {OperatingSystem -like "**server*"} -Properties "operatingsystem", "distinguishedname")}
            "Full"          {[array]$targetMachines = @(Get-ADComputer -Filter * -Properties "operatingsystem", "distinguishedname")}
            "Local"         {[array]$targetMachines = @(Get-ADComputer -Identity $env:ComputerName -Properties "operatingsystem", "distinguishedname")}
            "Targeted"      {[array]$targetMachines = @(Get-AdComputer -Identity $comp -Properties "operatingsystem","distinguishedname")}
        }

    Write-Output "`tIdentifying Organizational Units for $($targetMachines.count) systems."

    if (-not($Localhost))
    {
        if ($RootOrgUnit)
        {
            [array]$orgUnits = Get-ADOrganizationalUnit -SearchBase $SearchBase -SearchScope OneLevel
        }
        else
        {
            foreach ($targetMachine in $targetMachines)
            {
                if ($targetMachine.distinguishedname -like "CN=$($targetMachine.name),OU=Servers*")
                {
                    [array]$targetMachineOus += $targetMachine.distinguishedname.Replace("CN=$($targetMachine.name),OU=Servers,","")
                }
                elseif ($targetMachine.distinguishedName -like "*OU=Servers*")
                {
                    $oustring = ''
                    ($targetMachine.DistinguishedName.split(',')[3..10] | foreach { $oustring += "$_,"})
                    [array]$targetMachineOus += $ouString.trimend(',')
                }
                else
                {
                    [array]$targetMachineOus += $targetMachine.distinguishedname.Replace("CN=$($targetMachine.name),","")
                }
            }
            [array]$orgUnits = $targetMachineous | Get-Unique | ForEach-Object { Get-ADOrganizationalUnit -Filter {Distinguishedname -eq $_}}

            if ($Scope -eq "Full")
            {
                $orgUnits += "Computers"
            }
        }
        Write-Output "`tSystem Count - $($targetMachines.Count)"
    }
    else
    {
        Write-Output "`tGenerating Nodedata for LocalHost."
        [array]$orgUnits = "LocalHost"
    }

    foreach ($ou in $orgUnits)
    {
        if ($LocalHost)
        {
            $targetMachines = $env:ComputerName
            $ouFolder = "$nodeDataPath\LocalHost"
        }
        elseif ($ou -eq "Computers")
        {
            $targetMachines = (Get-ADComputer -Properties OperatingSystem -filter {OperatingSystem -like "*Windows 10*"} ).name
            $ouFolder = "$nodeDataPath\Windows 10"
        }
        else
        {
            $targetMachines = (Get-ADComputer -filter * -SearchBase $ou.DistinguishedName).name
            $ouFolder = "$nodeDataPath\$($ou.name)"
        }

        $ouMachineCount = $targetMachines.Count
        $currentMachineCount = 0

        if ($targetMachines.Count -gt 0)
        {
            if (-not (Test-Path $ouFolder))
            {
                $null = New-Item -Path $ouFolder -ItemType Directory -Force
            }

            if   ($ou -eq "Computers") {Write-Output "`t`t$ou - $ouMachineCount Node(s) identified"}
            else {Write-Output "`t`t$($ou.name) - $ouMachineCount Node(s) identified"}

            foreach ($machine in $TargetMachines)
            {
                $currentMachineCount++
                Write-Output "`t`t`tStarting Job ($currentMachineCount/$ouMachineCount) - Generate NodeData for $machine"
                $job = Start-Job -Scriptblock {
                    # Get Latest STIG files for each Stig Type
                    $rootPath           = $using:RootPath
                    $machine            = $using:machine
                    $LcmSettings        = $using:lcmsettings
                    $ouFolder           = $using:oufolder
                    $LocalHost          = $using:LocalHost
                    $nodeDataPath       = $using:NodeDataPath

                    if ($LocalHost)
                    {
                        $applicableStigs = @(Get-ApplicableStigs -Computername "LocalHost" -LocalHost)
                    }
                    else
                    {
                        $applicableStigs = @(Get-ApplicableStigs -Computername $machine)
                    }

                    switch -Wildcard ($applicableStigs)
                    {
                        "WindowsServer*"
                        {
                            switch -Wildcard ((Get-ADComputer -Identity $machine).DistinguishedName)
                            {
                                "*Domain Controllers*"  {$StigType = "DomainController";    $osRole = "DC"}
                                default                 {$StigType = "WindowsServer";       $osRole = "MS"}
                            }

                            $osVersion = ($ApplicableStigs | Where-Object {$_ -like "WindowsServer*"}).split("-")[1]
                            $osStigFiles = @{
                                orgSettings  = Get-StigFiles -Rootpath $RootPath -StigType $stigType -Version $osVersion -FileType "OrgSettings" -NodeName $machine
                                xccdfPath    = Get-StigFiles -Rootpath $RootPath -StigType $stigType -Version $osVersion -FileType "Xccdf" -NodeName $machine
                                manualChecks = Get-StigFiles -Rootpath $RootPath -StigType $stigType -Version $osVersion -FileType "ManualChecks" -NodeName $machine
                            }
                        }
                        "DotNetFramework"
                        {
                            $dotNetStigFiles = @{
                                orgsettings  = Get-StigFiles -Rootpath $Rootpath -StigType "DotNetFramework" -Version 4 -FileType "OrgSettings" -NodeName $machine
                                xccdfPath    = Get-StigFiles -Rootpath $Rootpath -StigType "DotNetFramework" -Version 4 -FileType "Xccdf" -NodeName $machine
                                manualChecks = Get-StigFiles -Rootpath $Rootpath -StigType "DotNetFramework" -Version 4 -FileType "ManualChecks" -NodeName $machine
                            }
                        }
                        "InternetExplorer"
                        {
                            $ieStigFiles = @{
                                xccdfPath      = Get-StigFiles -Rootpath $Rootpath -StigType "InternetExplorer" -Version 11 -FileType "Xccdf" -NodeName $machine
                                orgSettings    = Get-StigFiles -Rootpath $Rootpath -StigType "InternetExplorer" -Version 11 -FileType "OrgSettings" -NodeName $machine
                                manualChecks   = Get-StigFiles -Rootpath $Rootpath -StigType "InternetExplorer" -Version 11 -FileType "ManualChecks" -NodeName $machine
                            }
                        }
                        "WindowsClient"
                        {
                            $Win10StigFiles = @{
                                orgSettings  = Get-StigFiles -Rootpath $RootPath -StigType "WindowsClient" -Version $osVersion -FileType "OrgSettings" -NodeName $machine
                                xccdfPath    = Get-StigFiles -Rootpath $RootPath -StigType "WindowsClient" -Version $osVersion -FileType "Xccdf" -NodeName $machine
                                manualChecks = Get-StigFiles -Rootpath $RootPath -StigType "WindowsClient" -Version $osVersion -FileType "ManualChecks" -NodeName $machine
                            }
                        }
                        "WindowsDefender"
                        {
                            $WinDefenderStigFiles = @{
                                orgSettings  = Get-StigFiles -Rootpath $RootPath -StigType "WindowsDefender" -FileType "OrgSettings" -NodeName $machine
                                xccdfPath    = Get-StigFiles -Rootpath $RootPath -StigType "WindowsDefender" -FileType "Xccdf" -NodeName $machine
                                manualChecks = Get-StigFiles -Rootpath $RootPath -StigType "WindowsDefender" -FileType "ManualChecks" -NodeName $machine
                            }
                        }
                        "WindowsDnsServer"
                        {
                            $WindowsDnsStigFiles = @{
                                orgSettings  = Get-StigFiles -Rootpath $RootPath -StigType "WindowsDnsServer" -FileType "OrgSettings" -NodeName $machine
                                xccdfPath    = Get-StigFiles -Rootpath $RootPath -StigType "WindowsDnsServer" -FileType "Xccdf" -NodeName $machine
                                manualChecks = Get-StigFiles -Rootpath $RootPath -StigType "WindowsDnsServer" -FileType "ManualChecks" -NodeName $machine
                            }
                        }
                        "Office2016"
                        {
                            $word2016xccdfPath          = Get-StigFiles -Rootpath $Rootpath -StigType "Office2016_Word" -Version 16 -FileType "Xccdf" -NodeName $machine
                            $word2016orgSettings        = Get-StigFiles -Rootpath $Rootpath -StigType "Office2016_Word" -Version 16 -FileType "OrgSettings" -NodeName $machine
                            $word2016manualChecks       = Get-StigFiles -Rootpath $Rootpath -StigType "Office2016_Word" -Version 16 -FileType "ManualChecks" -NodeName $machine
                            $powerpoint2016xccdfPath    = Get-StigFiles -Rootpath $Rootpath -StigType "Office2016_PowerPoint" -Version 16 -FileType "Xccdf" -NodeName $machine
                            $powerpoint2016orgSettings  = Get-StigFiles -Rootpath $Rootpath -StigType "Office2016_PowerPoint" -Version 16 -FileType "OrgSettings" -NodeName $machine
                            $powerpoint2016manualChecks = Get-StigFiles -Rootpath $Rootpath -StigType "Office2016_PowerPoint" -Version 16 -FileType "ManualChecks" -NodeName $machine
                            $outlook2016xccdfPath       = Get-StigFiles -Rootpath $Rootpath -StigType "Office2016_Outlook" -Version 16 -FileType "Xccdf" -NodeName $machine
                            $outlook2016orgSettings     = Get-StigFiles -Rootpath $Rootpath -StigType "Office2016_Outlook" -Version 16 -FileType "OrgSettings" -NodeName $machine
                            $outlook2016manualChecks    = Get-StigFiles -Rootpath $Rootpath -StigType "Office2016_Outlook" -Version 16 -FileType "ManualChecks" -NodeName $machine
                            $excel2016xccdfPath         = Get-StigFiles -Rootpath $Rootpath -StigType "Office2016_Excel" -Version 16 -FileType "Xccdf" -NodeName $machine
                            $excel2016orgSettings       = Get-StigFiles -Rootpath $Rootpath -StigType "Office2016_Excel" -Version 16 -FileType "OrgSettings" -NodeName $machine
                            $excel2016manualChecks      = Get-StigFiles -Rootpath $Rootpath -StigType "Office2016_Excel" -Version 16 -FileType "ManualChecks" -NodeName $machine
                        }
                        "Office2013"
                        {
                            $word2013xccdfPath          = Get-StigFiles -Rootpath $Rootpath -StigType "Office2013_word" -Version 15 -FileType "Xccdf" -NodeName $machine
                            $word2013orgSettings        = Get-StigFiles -Rootpath $Rootpath -StigType "Office2013_word" -Version 15 -FileType "OrgSettings" -NodeName $machine
                            $word2013manualChecks       = Get-StigFiles -Rootpath $Rootpath -StigType "Office2013_word" -Version 15 -FileType "ManualChecks" -NodeName $machine
                            $powerpoint2013xccdfPath    = Get-StigFiles -Rootpath $Rootpath -StigType "Office2013_powerpoint" -Version 15 -FileType "Xccdf" -NodeName $machine
                            $powerpoint2013orgSettings  = Get-StigFiles -Rootpath $Rootpath -StigType "Office2013_powerpoint" -Version 15 -FileType "OrgSettings" -NodeName $machine
                            $powerpoint2013manualChecks = Get-StigFiles -Rootpath $Rootpath -StigType "Office2013_powerpoint" -Version 15 -FileType "ManualChecks" -NodeName $machine
                            $outlook2013xccdfPath       = Get-StigFiles -Rootpath $Rootpath -StigType "Office2013_outlook" -Version 15 -FileType "Xccdf" -NodeName $machine
                            $outlook2013orgSettings     = Get-StigFiles -Rootpath $Rootpath -StigType "Office2013_outlook" -Version 15 -FileType "OrgSettings" -NodeName $machine
                            $outlook2013manualChecks    = Get-StigFiles -Rootpath $Rootpath -StigType "Office2013_outlook" -Version 15 -FileType "ManualChecks" -NodeName $machine
                            $excel2013xccdfPath         = Get-StigFiles -Rootpath $Rootpath -StigType "Office2013_excel" -Version 15 -FileType "Xccdf" -NodeName $machine
                            $excel2013orgSettings       = Get-StigFiles -Rootpath $Rootpath -StigType "Office2013_excel" -Version 15 -FileType "OrgSettings" -NodeName $machine
                            $excel2013manualChecks      = Get-StigFiles -Rootpath $Rootpath -StigType "Office2013_excel" -Version 15 -FileType "ManualChecks" -NodeName $machine
                        }
                        "SQLServerInstance"
                        {
                            $version = "2016"
                            $sqlInstanceStigFiles = @{
                                xccdfPath      = Get-StigFiles -Rootpath $Rootpath -Version $Version -StigType "SqlServerInstance" -FileType "Xccdf" -NodeName $machine
                                orgSettings    = Get-StigFiles -Rootpath $Rootpath -Version $Version -StigType "SqlServerInstance" -FileType "OrgSettings" -NodeName $machine
                                manualChecks   = Get-StigFiles -Rootpath $Rootpath -Version $Version -StigType "SqlServerInstance" -FileType "ManualChecks" -NodeName $machine
                            }
                        }
                        "SqlServerDatabase"
                        {
                            $sqlDatabaseStigFiles = @{
                                xccdfPath      = Get-StigFiles -Rootpath $Rootpath -Version $Version -StigType "SqlServerDataBase" -FileType "Xccdf" -NodeName $machine
                                orgSettings    = Get-StigFiles -Rootpath $Rootpath -Version $Version -StigType "SqlServerDataBase" -FileType "OrgSettings" -NodeName $machine
                                manualChecks   = Get-StigFiles -Rootpath $Rootpath -Version $Version -StigType "SqlServerDataBase" -FileType "ManualChecks" -NodeName $machine
                            }
                        }
                        "WebSite*"
                        {
                            $iisVersion = Invoke-Command -ComputerName $machine -Scriptblock {
                                $iisData = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\InetStp"
                                $localIisVersion = "$($iisData.MajorVersion).$($iisData.MinorVersion)"
                                return $localiisVersion
                            }
                            $WebsiteStigFiles = @{
                                xccdfPath      = Get-StigFiles -Rootpath $Rootpath -StigType "WebSite" -Version $iisVersion -FileType "Xccdf" -NodeName $machine
                                orgSettings    = Get-StigFiles -Rootpath $Rootpath -StigType "WebSite" -Version $iisVersion -FileType "OrgSettings" -NodeName $machine
                                manualChecks   = Get-StigFiles -Rootpath $Rootpath -StigType "WebSite" -Version $iisVersion -FileType "ManualChecks" -NodeName $machine
                            }
                        }
                        "WebServer*"
                        {
                            [decimal]$iisVersion = Invoke-Command -ComputerName $machine -Scriptblock {
                                $iisData = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\InetStp"
                                $localIisVersion = "$($iisData.MajorVersion).$($iisData.MinorVersion)"
                                return $localiisVersion
                            }
                            $webServerStigFiles = @{
                                xccdfPath      = Get-StigFiles -Rootpath $Rootpath -StigType "WebServer" -Version $iisVersion -FileType "Xccdf" -NodeName $machine
                                orgSettings    = Get-StigFiles -Rootpath $Rootpath -StigType "WebServer" -Version $iisVersion -FileType "OrgSettings" -NodeName $machine
                                manualChecks   = Get-StigFiles -Rootpath $Rootpath -StigType "WebServer" -Version $iisVersion -FileType "ManualChecks" -NodeName $machine
                            }
                        }
                        "McAfee"
                        {
                            $mcafeeStigFiles = @{
                                xccdfPath      = Get-StigFiles -Rootpath $Rootpath -StigType "McAfee" -FileType "Xccdf" -NodeName $machine
                                orgSettings    = Get-StigFiles -Rootpath $Rootpath -StigType "McAfee" -FileType "OrgSettings" -NodeName $machine
                                manualChecks   = Get-StigFiles -Rootpath $Rootpath -StigType "McAfee" -FileType "ManualChecks" -NodeName $machine
                            }
                        }
                        "FireFox"
                        {
                            $fireFoxStigFiles = @{
                                xccdfPath      = Get-StigFiles -Rootpath $Rootpath -StigType "FireFox" -FileType "Xccdf" -NodeName $machine
                                orgSettings    = Get-StigFiles -Rootpath $Rootpath -StigType "FireFox" -FileType "OrgSettings" -NodeName $machine
                                manualChecks   = Get-StigFiles -Rootpath $Rootpath -StigType "FireFox" -FileType "ManualChecks" -NodeName $machine
                            }
                        }
                        "Edge"
                        {
                            $edgeStigFiles = @{
                                xccdfPath      = Get-StigFiles -Rootpath $Rootpath -StigType "Edge" -FileType "Xccdf" -NodeName $machine
                                orgSettings    = Get-StigFiles -Rootpath $Rootpath -StigType "Edge" -FileType "OrgSettings" -NodeName $machine
                                manualChecks   = Get-StigFiles -Rootpath $Rootpath -StigType "Edge" -FileType "ManualChecks" -NodeName $machine
                            }
                        }
                        "Chrome"
                        {
                            $chromeStigFiles = @{
                                xccdfPath      = Get-StigFiles -Rootpath $Rootpath -StigType "Chrome" -FileType "Xccdf" -NodeName $machine
                                orgSettings    = Get-StigFiles -Rootpath $Rootpath -StigType "Chrome" -FileType "OrgSettings" -NodeName $machine
                                manualChecks   = Get-StigFiles -Rootpath $Rootpath -StigType "Chrome" -FileType "ManualChecks" -NodeName $machine
                            }
                        }
                        "OracleJRE"
                        {
                            $oracleStigFiles = @{
                                xccdfPath      = Get-StigFiles -Rootpath $Rootpath -StigType "OracleJRE" -FileType "Xccdf" -NodeName $machine
                                orgSettings    = Get-StigFiles -Rootpath $Rootpath -StigType "OracleJRE" -FileType "OrgSettings" -NodeName $machine
                                manualChecks   = Get-StigFiles -Rootpath $Rootpath -StigType "OracleJRE" -FileType "ManualChecks" -NodeName $machine
                            }
                        }

                    }

                    #region Generate Configuration Data
                    if ($LocalHost)
                    {
                        $compName = $env:ComputerName
                        $configContent = "@{`n`tNodeName = `"$compName`"`n`n"
                    }
                    else
                    {
                        $configContent = "@{`n`tNodeName = `"$machine`"`n`n"
                    }
                    $configContent += "`tLocalConfigurationManager ="
                    $configContent += "`n`t@{"

                    foreach ($setting in $LcmSettings.Keys)
                    {

                        if (($Null -ne $LcmSettings.$setting) -and ("{}" -ne $lcmsettings.$setting) -and ("" -ne $LcmSettings.$setting))
                        {
                            $configContent += "`n`t`t$($setting)"

                            if ($setting.Length -lt 8)      {$configContent += "`t`t`t`t`t`t`t= "}
                            elseif ($setting.Length -lt 12) {$configContent += "`t`t`t`t`t`t= "}
                            elseif ($setting.Length -lt 16) {$configContent += "`t`t`t`t`t= "}
                            elseif ($setting.Length -lt 20) {$configContent += "`t`t`t`t= "}
                            elseif ($setting.Length -lt 24) {$configContent += "`t`t`t= "}
                            elseif ($setting.Length -lt 28) {$configContent += "`t`t= "}
                            elseif ($setting.Length -lt 32) {$configContent += "`t= "}

                            if (($LcmSettings.$setting -eq $true) -or ($LcmSettings.$setting -eq $false))
                            {
                                $configContent += "`$$($LcmSettings.$setting)"
                            }
                            else
                            {
                                $configContent += "`"$($LcmSettings.$setting)`""
                            }
                        }
                    }

                    #Generate STIG ConfigData
                    $configContent += "`n`t}"
                    $configContent += "`n`n`tAppliedConfigurations  ="
                    $configContent += "`n`t@{"

                    switch -Wildcard ($applicableSTIGs)
                    {
                        "WindowsServer*"
                        {
                            $configContent += "`n`n`t`tPowerSTIG_WindowsServer ="
                            $configContent += "`n`t`t@{"
                            $configContent += "`n`t`t`tOSRole               = `"$osRole`""
                            $configContent += "`n`t`t`tOsVersion            = `"$osVersion`""
                            $configContent += "`n`t`t`tOrgSettings          = `"$($osStigFiles.orgSettings)`""
                            $configContent += "`n`t`t`tManualChecks         = `"$($osStigFiles.manualChecks)`""
                            $configContent += "`n`t`t`txccdfPath            = `"$($osStigFiles.xccdfPath)`""
                            $configContent += "`n`t`t}"
                        }
                        "InternetExplorer"
                        {
                            $configContent += "`n`n`t`tPowerSTIG_InternetExplorer ="
                            $configContent += "`n`t`t@{"
                            $configContent += "`n`t`t`tBrowserVersion 		= `"11`""
                            $configContent += "`n`t`t`tOrgSettings			= `"$($ieStigFiles.orgSettings)`""
                            $configContent += "`n`t`t`txccdfPath			= `"$($ieStigFiles.xccdfPath)`""
                            $configContent += "`n`t`t`tSkipRule 			= `"V-46477`""
                            $configContent += "`n`t`t}"
                        }
                        "DotnetFrameWork"
                        {
                            $configContent += "`n`n`t`tPowerSTIG_DotNetFrameWork ="
                            $configContent += "`n`t`t@{"
                            $configContent += "`n`t`t`tFrameWorkVersion 	= `"4`""
                            $configContent += "`n`t`t`txccdfPath			= `"$($dotNetStigFiles.xccdfPath)`""
                            $configContent += "`n`t`t`tOrgSettings			= `"$($dotNetStigFiles.orgSettings)`""
                            $configContent += "`n`t`t`tManualChecks 		= `"$($dotNetStigFiles.manualChecks)`""
                            $configContent += "`n`t`t}"
                        }
                        "WindowsClient"
                        {
                            $configContent += "`n`n`t`tPowerSTIG_WindowsClient ="
                            $configContent += "`n`t`t@{"
                            $configContent += "`n`t`t`tOSVersion            = `"10`""
                            $configContent += "`n`t`t`tOrgSettings          = `"$($win10StigFiles.orgSettings)`""
                            $configContent += "`n`t`t`tManualChecks         = `"$($win10StigFiles.manualChecks)`""
                            $configContent += "`n`t`t`txccdfPath            = `"$($win10StigFiles.xccdfPath)`""
                            $configContent += "`n`t`t}"
                        }
                        "WindowsDefender"
                        {
                            $configContent += "`n`n`t`tPowerSTIG_WindowsDefender ="
                            $configContent += "`n`t`t@{"
                            $configContent += "`n`t`t`tOrgSettings          = `"$($winDefenderStigFiles.orgSettings)`""
                            $configContent += "`n`t`t`tManualChecks         = `"$($winDefenderStigFiles.manualChecks)`""
                            $configContent += "`n`t`t`txccdfPath            = `"$($winDefenderStigFiles.xccdfPath)`""
                            $configContent += "`n`t`t}"
                        }
                        "WindowsDnsServer"
                        {
                            $configContent += "`n`n`t`tPowerSTIG_WindowsDNSServer ="
                            $configContent += "`n`t`t@{"
                            $configContent += "`n`t`t`tOsVersion            = `"$osVersion`""
                            $configContent += "`n`t`t`txccdfPath            = `"$($WindowsDnsStigFiles.xccdfPath)`""
                            $configContent += "`n`t`t`tOrgSettings          = `"$($WindowsDnsStigFiles.orgSettings)`""
                            $configContent += "`n`t`t`tManualChecks         = `"$($WindowsDnsStigFiles.manualChecks)`""
                            $configContent += "`n`t`t}"
                        }
                        "Office2016*"
                        {
                            $configContent += "`n`n`t`tPowerSTIG_Office2016_Excel ="
                            $configContent += "`n`t`t@{"
                            $configContent += "`n`t`t`tOrgSettings  = `"$Excel2016OrgSettings`""
                            $configContent += "`n`t`t`tManualChecks = `"$Excel2016ManualChecks`""
                            $configContent += "`n`t`t`txccdfPath    = `"$Excel2016xccdfPath`""
                            $configContent += "`n`t`t}"
                            $configContent += "`n`n`t`tPowerSTIG_Office2016_Outlook ="
                            $configContent += "`n`t`t@{"
                            $configContent += "`n`t`t`tOrgSettings  = `"$Outlook2016OrgSettings`""
                            $configContent += "`n`t`t`tManualChecks = `"$Outlook2016ManualChecks`""
                            $configContent += "`n`t`t`txccdfPath    = `"$Outlook2016xccdfPath`""
                            $configContent += "`n`t`t}"
                            $configContent += "`n`n`t`tPowerSTIG_Office2016_PowerPoint ="
                            $configContent += "`n`t`t@{"
                            $configContent += "`n`t`t`tOrgSettings  = `"$PowerPoint2016OrgSettings`""
                            $configContent += "`n`t`t`tManualChecks = `"$PowerPoint2016ManualChecks`""
                            $configContent += "`n`t`t`txccdfPath    = `"$PowerPoint2016xccdfPath`""
                            $configContent += "`n`t`t}"
                            $configContent += "`n`n`t`tPowerSTIG_Office2016_Word ="
                            $configContent += "`n`t`t@{"
                            $configContent += "`n`t`t`tOrgSettings  = `"$Word2016OrgSettings`""
                            $configContent += "`n`t`t`tManualChecks = `"$Word2016ManualChecks`""
                            $configContent += "`n`t`t`txccdfPath    = `"$Word2016xccdfPath`""
                            $configContent += "`n`t`t}"
                        }
                        "Office2013*"
                        {
                            $configContent += "`n`n`t`tPowerSTIG_Office2013_Excel ="
                            $configContent += "`n`t`t@{"
                            $configContent += "`n`t`t`tOrgSettings  = `"$Excel2013OrgSettings`""
                            $configContent += "`n`t`t`tManualChecks = `"$Excel2013ManualChecks`""
                            $configContent += "`n`t`t`txccdfPath    = `"$Excel2013xccdfPath`""
                            $configContent += "`n`t`t}"
                            $configContent += "`n`n`t`tPowerSTIG_Office2013_Outlook ="
                            $configContent += "`n`t`t@{"
                            $configContent += "`n`t`t`tOrgSettings  = `"$Outlook2013OrgSettings`""
                            $configContent += "`n`t`t`tManualChecks = `"$Outlook2013ManualChecks`""
                            $configContent += "`n`t`t`txccdfPath    = `"$Outlook2013xccdfPath`""
                            $configContent += "`n`t`t}"
                            $configContent += "`n`n`t`tPowerSTIG_Office2013_PowerPoint ="
                            $configContent += "`n`t`t@{"
                            $configContent += "`n`t`t`tOrgSettings  = `"$PowerPoint2013OrgSettings`""
                            $configContent += "`n`t`t`tManualChecks = `"$PowerPoint2013ManualChecks`""
                            $configContent += "`n`t`t`txccdfPath    = `"$PowerPoint2013xccdfPath`""
                            $configContent += "`n`t`t}"
                            $configContent += "`n`n`t`tPowerSTIG_Office2013_Word ="
                            $configContent += "`n`t`t@{"
                            $configContent += "`n`t`t`tOrgSettings  = `"$Word2013OrgSettings`""
                            $configContent += "`n`t`t`tManualChecks = `"$Word2013ManualChecks`""
                            $configContent += "`n`t`t`txccdfPath    = `"$Word2013xccdfPath`""
                            $configContent += "`n`t`t}"
                        }
                        "Website*"
                        {
                            $websites = @(Invoke-Command -Computername $Machine -Scriptblock { Import-Module WebAdministration;Return (Get-Childitem "IIS:\Sites").name})
                            $appPools = @(Invoke-Command -Computername $Machine -Scriptblock { Import-Module WebAdministration;Return (Get-Childitem "IIS:\AppPools").name})
                            [string]$allWebSites = ''
                            [string]$allAppPools = ''
                            if ($websites.count -gt 1)
                            {
                                foreach ($site in $websites)
                                {
                                    $allWebsites += "`"$site`","
                                }
                                $websiteString = $allWebsites.TrimEnd(",")
                            }
                            else
                            {
                                $websiteString = "`"$websites`""
                            }

                            if ($appPools.count -gt 1)
                            {
                                foreach ($appPool in $appPools)
                                {
                                    $allAppPools += "`"$appPool`","
                                }
                                $appPoolString = $allAppPools.TrimEnd(",")
                            }
                            else
                            {
                                $appPoolString = "`"$appPools`""
                            }

                            $configContent += "`n`n`t`tPowerSTIG_WebSite ="
                            $configContent += "`n`t`t@{"
                            $configContent += "`n`t`t`tIISVersion       = `"$IISVersion`""
                            $configContent += "`n`t`t`tWebsiteName      = $websiteString"
                            $configContent += "`n`t`t`tWebAppPool       = $appPoolString"
                            $configContent += "`n`t`t`tXccdfPath        = `"$($webSiteStigFiles.XccdfPath)`""
                            $configContent += "`n`t`t`tOrgSettings      = `"$($webSiteStigFiles.OrgSettings)`""
                            $configContent += "`n`t`t`tManualChecks     = `"$($webSiteStigFiles.ManualChecks)`""
                            $configContent += "`n`t`t}"
                        }
                        "WebServer*"
                        {
                            $configContent += "`n`n`t`tPowerSTIG_WebServer ="
                            $configContent += "`n`t`t@{"
                            $configContent += "`n`t`t`tSkipRule         = `"V-214429`""
                            $configContent += "`n`t`t`tIISVersion       = `"$IISVersion`""
                            $configContent += "`n`t`t`tLogPath          = `"C:\InetPub\Logs`""
                            $configContent += "`n`t`t`tXccdfPath        = `"$($webServerStigFiles.XccdfPath)`""
                            $configContent += "`n`t`t`tOrgSettings      = `"$($webServerStigFiles.OrgSettings)`""
                            $configContent += "`n`t`t`tManualChecks     = `"$($webServerStigFiles.ManualChecks)`""
                            $configContent += "`n`t`t}"
                        }
                        "FireFox"
                        {
                            $configContent += "`n`n`t`tPowerSTIG_Firefox ="
                            $configContent += "`n`t`t@{"
                            $configContent += "`n`t`t`tInstallDirectory      = `"C:\Program Files\Mozilla Firefox`""
                            $configContent += "`n`t`t`txccdfPath			= `"$($firefoxStigFiles.XccdfPath)`""
                            $configContent += "`n`t`t`tOrgSettings			= `"$($firefoxStigFiles.OrgSettings)`""
                            $configContent += "`n`t`t`tManualChecks 		= `"$($firefoxStigFiles.ManualChecks)`""
                            $configContent += "`n`t`t}"
                        }
                        "Edge"
                        {
                            $configContent += "`n`n`t`tPowerSTIG_Edge ="
                            $configContent += "`n`t`t@{"
                            $configContent += "`n`t`t`tOrgSettings          = `"$($edgeStigFiles.orgSettings)`""
                            $configContent += "`n`t`t`tManualChecks         = `"$($edgeStigFiles.manualChecks)`""
                            $configContent += "`n`t`t`txccdfPath            = `"$($edgeStigFiles.xccdfPath)`""
                            $configContent += "`n`t`t}"
                        }
                        "Chrome"
                        {
                            $configContent += "`n`n`t`tPowerSTIG_Chrome ="
                            $configContent += "`n`t`t@{"
                            $configContent += "`n`t`t`tOrgSettings          = `"$($chromeStigFiles.orgSettings)`""
                            $configContent += "`n`t`t`tManualChecks         = `"$($chromeStigFiles.manualChecks)`""
                            $configContent += "`n`t`t`txccdfPath            = `"$($chromeStigFiles.xccdfPath)`""
                            $configContent += "`n`t`t}"
                        }
                        "OracleJRE"
                        {
                            $configContent += "`n`n`t`tPowerSTIG_OracleJRE ="
                            $configContent += "`n`t`t@{"
                            $configContent += "`n`t`t`tConfigPath       = `"$ConfigPath`""
                            $configContent += "`n`t`t`tPropertiesPath   = `"$PropertiesPath`""
                            $configContent += "`n`t`t`tXccdfPath        = `"$($oracleStigFiles.XccdfPath)`""
                            $configContent += "`n`t`t`tOrgSettings      = `"$($oracleStigFiles.OrgSettings)`""
                            $configContent += "`n`t`t`tManualChecks     = `"$($oracleStigFiles.ManualChecks)`""
                            $configContent += "`n`t`t}"
                        }
                        # "Mcafee"
                        # {
                        #     $configContent += "`n`n`t`tPowerSTIG_McAfee ="
                        #     $configContent += "`n`t`t@{"
                        #     $configContent += "`n`t`t`tTechnology       = `"VirusScan`""
                        #     $configContent += "`n`t`t`tVersion          = `"8.8`""
                        #     $configContent += "`n`t`t`tXccdfPath        = `"$($mcafeeStigFiles.XccdfPath)`""
                        #     $configContent += "`n`t`t`tOrgSettings      = `"$($mcafeeStigFiles.OrgSettings)`""
                        #     $configContent += "`n`t`t`tManualChecks     = `"$($mcafeeStigFiles.ManualChecks)`""
                        #     $configContent += "`n`t`t}"
                        # }
                        # "SqlServerInstance"
                        # {
                        #     $configContent += "`n`n`t`tPowerSTIG_SQLServer_Instance ="
                        #     $configContent += "`n`t`t@{"
                        #     $configContent += "`n`t`t`tSqlRole          = `"$sqlRole`""
                        #     $configContent += "`n`t`t`tSqlVersion       = `"$sqlVersion`""
                        #     $configContent += "`n`t`t`tServerInstance   = `"$sqlServerInstance`""
                        #     $configContent += "`n`t`t`tXccdfPath        = `"$($sqlinstanceStigFiles.XccdfPath)`""
                        #     $configContent += "`n`t`t`tOrgSettings      = `"$($sqlinstanceStigFiles.OrgSettings)`""
                        #     $configContent += "`n`t`t`tManualChecks     = `"$($sqlinstanceStigFiles.ManualChecks)`""
                        #     $configContent += "`n`t`t}"
                        #     $configContent += "`n"
                        # }
                        # "SqlServerDatabase"
                        # {
                        #     $configContent += "`n`n`t`tPowerSTIG_SQLServer_Database ="
                        #     $configContent += "`n`t`t@{"
                        #     $configContent += "`n`t`t`tSqlRole          = `"$sqlRole`""
                        #     $configContent += "`n`t`t`tSqlVersion       = `"$sqlVersion`""
                        #     $configContent += "`n`t`t`tServerInstance   = `"$sqlServerInstance`""
                        #     $configContent += "`n`t`t`tXccdfPath        = `"$($sqlDatabseStigFiles.XccdfPath)`""
                        #     $configContent += "`n`t`t`tOrgSettings      = `"$($sqlDatabaseStigFiles.OrgSettings)`""
                        #     $configContent += "`n`t`t`tManualChecks     = `"$($sqlDatabaseStigFiles.ManualChecks)`""
                        #     $configContent += "`n`t`t}"
                        #     $configContent += "`n"
                        # }
                    }

                    $configContent += "`n`t}"
                    $configContent += "`n}"

                    if ($LocalHost)
                    {
                        $compName = $env:ComputerName
                        $nodeDataFile = New-Item -Path "$nodeDataPath\$CompName\$CompName.psd1" -Force
                    }
                    else
                    {
                        $nodeDataFile = New-Item -Path "$ouFolder\$machine.psd1" -Force
                    }
                    $null = Set-Content -path $nodeDataFile $configContent
                }
                $jobs += $job.Id
            }
        }
    }
    Write-Output "`tJob creation for nodedata generation is complete. Waiting on $($jobs.count) jobs to finish processing.`n"
    Get-Job -ID $jobs | Wait-Job | Receive-Job
}

function Get-StigFiles
{
    param(

    [Parameter()]
    [string]
    $FileType,

    [Parameter()]
    [string]
    $StigType,

    [Parameter()]
    [string]
    $RootPath = (Get-Location).Path,

    [Parameter()]
    [string]
    $Version,

    [Parameter()]
    [string]
    $NodeName

    )

    $xccdfArchive       = (Resolve-Path -Path "$RootPath\*Resources\Stig Data\XCCDFs").Path
    $manualCheckFolder  = (Resolve-Path -Path "$RootPath\*Resources\Stig Data\Manual Checks").Path
    $orgSettingsFolder  = (Resolve-Path -Path "$RootPath\*Resources\Stig Data\Organizational Settings").Path
    $stigFilePath       = ''

    switch ($fileType)
    {
        "Xccdf"
        {
            switch -WildCard ($stigType)
            {
                "WindowsServer"
                {
                    $xccdfContainer = (Resolve-Path -Path "$xccdfArchive\Windows.Server.$version" -ErrorAction SilentlyContinue).Path
                    switch ($version)
                    {
                        "2012R2"    {$xccdfs = (Get-ChildItem -Path "$xccdfContainer\*.xml" | Where-Object { $_.name -notlike "*DC*" }).Name}
                        "2016"      {$xccdfs = (Get-ChildItem -Path "$xccdfContainer\*$version`_STIG*.xml").Name}
                        "2019"      {$xccdfs = (Get-ChildItem -Path "$xccdfContainer\*$version`_STIG*.xml").Name}
                    }
                }
                "DomainController"
                {
                    $xccdfContainer = (Resolve-Path -Path "$xccdfArchive\Windows.Server.$version" -ErrorAction SilentlyContinue).Path
                    switch ($version)
                    {
                        "2012R2"    {$xccdfs = (Get-ChildItem -Path "$xccdfContainer\*.xml" | Where-Object { $_.name -like "*DC*" }).Name}
                        "2016"      {$xccdfs = (Get-ChildItem -Path "$xccdfContainer\*$version`_STIG*.xml").Name}
                        "2019"      {$xccdfs = (Get-ChildItem -Path "$xccdfContainer\*$version`_STIG*.xml").Name}
                    }
                }
                "WindowsClient"
                {
                    $xccdfContainer     = (Resolve-Path -Path "$xccdfArchive\Windows.Client" -ErrorAction SilentlyContinue).Path
                    $xccdfs             = (Get-ChildItem -Path "$xccdfContainer\*.xml").name
                }
                "DotNetFramework"
                {
                    $xccdfContainer     = (Resolve-Path -Path "$xccdfArchive\DotNet" -ErrorAction SilentlyContinue).Path
                    $xccdfs             = (Get-ChildItem -Path "$xccdfContainer\*.xml" | Where-Object { $_.name -like "*$Version*STIG*Manual-xccdf.xml"}).name
                }
                "InternetExplorer"
                {
                    $xccdfContainer     = (Resolve-Path -Path "$xccdfArchive\$StigType" -ErrorAction SilentlyContinue).Path
                    $xccdfs             = (Get-ChildItem -Path "$xccdfContainer\*.xml" | Where-Object { $_.name -like "*xccdf.xml"}).name
                }
                "WebServer"
                {
                    $xccdfContainer     = (Resolve-Path -Path "$xccdfArchive\Web Server" -ErrorAction SilentlyContinue).Path
                    $xccdfs             = (Get-ChildItem -Path "$xccdfContainer\*.xml" | Where-Object { $_.name -like "*$($Version.replace(".","-"))*Server*xccdf.xml"}).name
                }
                "WebSite"
                {
                    $xccdfContainer     = (Resolve-Path -Path "$xccdfArchive\Web Server" -ErrorAction SilentlyContinue).Path
                    $xccdfs             = (Get-ChildItem -Path "$xccdfContainer\*.xml" | Where-Object { $_.name -like "*$($Version.replace(".","-"))*Site*xccdf.xml"}).name
                }
                "FireFox"
                {
                    $xccdfContainer     = (Resolve-Path -Path "$xccdfArchive\browser" -ErrorAction SilentlyContinue).Path
                    $xccdfs             = (Get-ChildItem -Path "$xccdfContainer\*.xml" | Where-Object { $_.name -like "*FireFox*xccdf.xml"}).name
                }
                "Edge"
                {
                    $xccdfContainer     = (Resolve-Path -Path "$xccdfArchive\Edge" -ErrorAction SilentlyContinue).Path
                    $xccdfs             = (Get-ChildItem -Path "$xccdfContainer\*.xml" | Where-Object { $_.name -like "*edge*xccdf.xml"}).name
                }
                "Chrome"
                {
                    $xccdfContainer     = (Resolve-Path -Path "$xccdfArchive\Chrome" -ErrorAction SilentlyContinue).Path
                    $xccdfs             = (Get-ChildItem -Path "$xccdfContainer\*.xml" | Where-Object { $_.name -like "*chrome*xccdf.xml"}).name
                }
                "McAfee"
                {
                    $xccdfContainer     = (Resolve-Path -Path "$xccdfArchive\$StigType" -ErrorAction SilentlyContinue).Path
                    $xccdfs             = (Get-ChildItem -Path "$xccdfContainer\*.xml" | Where-Object { $_.name -like "*McAfee*xccdf.xml"}).name
                }
                "Office*"
                {
                    $officeApp          = $stigType.split('_')[1]
                    $officeVersion      = $stigType.split('_')[0].Replace('Office',"")
                    $xccdfContainer     = (Resolve-Path -Path "$xccdfArchive\Office" -ErrorAction SilentlyContinue).Path
                    $xccdfs             = (Get-ChildItem -Path "$xccdfContainer\*$officeApp*.xml" | Where-Object { $_.name -like "*$officeversion*"}).name
                }
                "OracleJRE"
                {
                    $xccdfContainer     = (Resolve-Path -Path "$xccdfArchive\$StigType" -ErrorAction SilentlyContinue).Path
                    $xccdfs             = (Get-ChildItem -Path "$xccdfContainer\*.xml" | Where-Object { $_.name -like "*Oracle*JRE*$version*xccdf.xml"}).name
                }
                "WindowsDefender"
                {
                    $xccdfContainer     = (Resolve-Path -Path "$xccdfArchive\Windows.Defender" -ErrorAction SilentlyContinue).Path
                    $xccdfs             = (Get-ChildItem -Path "$xccdfContainer\*.xml" | Where-Object { $_.name -like "*Windows*Defender*xccdf.xml"}).name
                }
                "WindowsDNSServer"
                {
                    $xccdfContainer     = (Resolve-Path -Path "$xccdfArchive\Windows.Dns" -ErrorAction SilentlyContinue).Path
                    $xccdfs             = (Get-ChildItem -Path "$xccdfContainer\*.xml" | Where-Object { $_.name -like "*xccdf.xml"}).name
                }
                "AdobeReader"
                {
                    $xccdfContainer     = (Resolve-Path -Path "$xccdfArchive\$StigType" -ErrorAction SilentlyContinue).Path
                    $xccdfs             = (Get-ChildItem -Path "$xccdfContainer\*.xml" | Where-Object { $_.name -like "*Adobe*Reader*xccdf.xml"}).name
                }
                "SqlServerInstance"
                {
                    $xccdfContainer     = (Resolve-Path -Path "$xccdfArchive\SQL Server" -ErrorAction SilentlyContinue).Path
                    $xccdfs             = (Get-ChildItem -Path "$xccdfContainer\*.xml" | Where-Object { $_.name -like "*SQL*$Version*Instance*xccdf.xml"}).name
                }
                "SqlServerDatabase"
                {
                    $xccdfContainer     = (Resolve-Path -Path "$xccdfArchive\SQL Server" -ErrorAction SilentlyContinue).Path
                    $xccdfs             = (Get-ChildItem -Path "$xccdfContainer\*.xml" | Where-Object { $_.name -like "*SQL*$version*Database*xccdf.xml"}).name
                }
            }
            $stigVersions       = $xccdfs | Select-String "V(\d+)R(\d+)" -AllMatches | Foreach-Object {$_.Matches.Value}
            $latestVersion      = ($stigversions | Measure-Object -Maximum).Maximum
            $xccdfFileName      = $xccdfs | Where { $_ -like "*$latestVersion*-xccdf.xml"}
            $stigFilePath       = "$xccdfContainer\$xccdfFileName"
        }
        "ManualChecks"
        {
            switch -wildcard ($stigType)
            {
                "WindowsServer"
                {
                    $manualCheckContainer   = (Resolve-Path -Path "$manualCheckFolder\WindowsServer" -ErrorAction SilentlyContinue).Path
                    $manualCheckFiles       = (Get-ChildItem -Path $manualCheckContainer | Where-Object {$_.name -like "*$version*MS*.psd1"}).basename
                }
                "DomainController"
                {
                    $manualCheckContainer   = (Resolve-Path -Path "$manualCheckFolder\WindowsServer" -ErrorAction SilentlyContinue).Path
                    $manualCheckFiles       = (Get-ChildItem -Path $manualCheckContainer | Where-Object {$_.name -like "*$version*DC*.psd1"}).basename
                    $stigVersions           = $manualCheckFiles | Select-String "(\d+)R(\d+)" -AllMatches | Foreach-Object {$_.Matches.Value}
                    $latestVersion          = ($stigVersions | Measure-Object -Maximum).Maximum
                    $manualCheckFileName    = $manualCheckFiles | Where-Object { $_ -like "*WindowsServer*$latestVersion*" }
                    $stigFilePath           = "$manualCheckContainer\$manualCheckFileName.psd1"
                }
                "WindowsClient"
                {
                    $manualCheckContainer   = (Resolve-Path -Path "$manualCheckFolder\WindowsClient" -ErrorAction SilentlyContinue).Path
                    $manualCheckFiles       = (Get-ChildItem -Path $manualCheckContainer).basename
                }
                "DotNetFramework"
                {
                    $manualCheckContainer   = (Resolve-Path -Path "$manualCheckFolder\DotnetFramework" -ErrorAction SilentlyContinue).Path
                    $manualCheckFiles       = (Get-ChildItem -Path $manualCheckContainer | Where-Object { $_.name -like "*DotNetFramework*ManualChecks.psd1"}).basename
                }
                "InternetExplorer"
                {
                    $manualCheckContainer   = (Resolve-Path -Path "$manualCheckFolder\InternetExplorer" -ErrorAction SilentlyContinue).Path
                    $manualCheckFiles       = (Get-ChildItem -Path $manualCheckContainer | Where-Object { $_.name -like "*InternetExplorer*ManualChecks.psd1"}).basename
                }
                "WebServer"
                {
                    $manualCheckContainer   = (Resolve-Path -Path "$manualCheckFolder\WebServer" -ErrorAction SilentlyContinue).Path
                    $manualCheckFiles       = (Get-ChildItem -Path $manualCheckContainer | Where-Object { $_.name -like "*WebServer*$Version*-ManualChecks.psd1"}).basename
                }
                "WebSite"
                {
                    $manualCheckContainer   = (Resolve-Path -Path "$manualCheckFolder\WebSite" -ErrorAction SilentlyContinue).Path
                    $manualCheckFiles       = (Get-ChildItem -Path $manualCheckContainer | Where-Object { $_.name -like "*WebSite-$Version*ManualChecks.psd1"}).basename
                }
                "FireFox"
                {
                    $manualCheckContainer   = (Resolve-Path -Path "$manualCheckFolder\FireFox" -ErrorAction SilentlyContinue).Path
                    $manualCheckFiles       = (Get-ChildItem -Path $manualCheckContainer | Where-Object { $_.name -like "*FireFox*ManualChecks.psd1"}).basename
                }
                "Chrome"
                {
                    $manualCheckContainer   = (Resolve-Path -Path "$manualCheckFolder\Chrome" -ErrorAction SilentlyContinue).Path
                    $manualCheckFiles       = (Get-ChildItem -Path $manualCheckContainer | Where-Object { $_.name -like "*Chrome*ManualChecks.psd1"}).basename
                }
                "Edge"
                {
                    $manualCheckContainer   = (Resolve-Path -Path "$manualCheckFolder\Edge" -ErrorAction SilentlyContinue).Path
                    $manualCheckFiles       = (Get-ChildItem -Path $manualCheckContainer | Where-Object { $_.name -like "*Edge*ManualChecks.psd1"}).basename
                }
                "McAfee"
                {
                    $manualCheckContainer   = (Resolve-Path -Path "$manualCheckFolder\McAfee" -ErrorAction SilentlyContinue).Path
                    $manualCheckFiles       = (Get-ChildItem -Path $manualCheckContainer | Where-Object { $_.name -like "*McAfee*ManualChecks.psd1"}).basename
                }
                "Office2016*"
                {
                    $officeApp              = $stigType.split('_')[1]
                    $officeVersion          = $stigType.split('_')[0].TrimStart("office")
                    $manualCheckContainer   = (Resolve-Path -Path "$manualCheckFolder\Office" -ErrorAction SilentlyContinue).Path
                    $manualCheckFiles       = (Get-ChildItem -Path $manualCheckContainer | Where-Object { $_.name -like "*$officeApp*ManualChecks.psd1"}).basename
                    $stigVersions           = $manualCheckFiles | Select-String "(\d+)R(\d+)" -AllMatches | Foreach-Object {$_.Matches.Value}
                    $latestVersion          = ($stigVersions | Measure-Object -Maximum).Maximum
                    $manualCheckFileName    = $manualCheckFiles | Where-Object { $_ -like "*$officeApp*$latestVersion*" }
                    $stigFilePath           = "$manualCheckContainer\$manualCheckFileName.psd1"
                }
                "Office2013*"
                {
                    $officeApp              = $stigType.split('_')[1]
                    $officeVersion          = $stigType.split('_')[0].TrimStart("office")
                    $manualCheckContainer   = (Resolve-Path -Path "$manualCheckFolder\Office_2013" -ErrorAction SilentlyContinue).Path
                    $manualCheckFiles       = (Get-ChildItem -Path $manualCheckContainer | Where-Object { $_.name -like "*$officeApp*ManualChecks.psd1"}).basename
                    $stigVersions           = $manualCheckFiles | Select-String "(\d+)R(\d+)" -AllMatches | Foreach-Object {$_.Matches.Value}
                    $latestVersion          = ($stigVersions | Measure-Object -Maximum).Maximum
                    $manualCheckFileName    = $manualCheckFiles | Where-Object { $_ -like "*$officeApp*$latestVersion*" }
                    $stigFilePath           = "$manualCheckContainer\$manualCheckFileName.psd1"
                }
                "OracleJRE"
                {
                    $manualCheckContainer   = (Resolve-Path -Path "$manualCheckFolder\OracleJRE" -ErrorAction SilentlyContinue).Path
                    $manualCheckFiles       = (Get-ChildItem -Path $manualCheckContainer | Where-Object { $_.name -like "*OracleJRE*$version*.psd1"}).basename
                }
                "WindowsDefender"
                {
                    $manualCheckContainer   = (Resolve-Path -Path "$manualCheckFolder\WindowsDefender" -ErrorAction SilentlyContinue).Path
                    $manualCheckFiles       = (Get-ChildItem -Path $manualCheckContainer | Where-Object { $_.name -like "*WindowsDefender*ManualChecks.psd1"}).basename
                }
                "WindowsDNSServer"
                {
                    $manualCheckContainer   = (Resolve-Path -Path "$manualCheckFolder\WindowsDnsServer" -ErrorAction SilentlyContinue).Path
                    $manualCheckFiles       = (Get-ChildItem -Path $manualCheckContainer | Where-Object { $_.name -like "*DNSServer*ManualChecks.psd1"}).basename
                }
                "AdobeReader"
                {
                    $manualCheckContainer   = (Resolve-Path -Path "$manualCheckFolder\Adobe" -ErrorAction SilentlyContinue).Path
                    $manualCheckFiles       = (Get-ChildItem -Path $manualCheckContainer | Where-Object { $_.name -like "*Adobe*ManualChecks.psd1"}).basename
                }
                "SqlServerInstance"
                {
                    $manualCheckContainer   = (Resolve-Path -Path "$manualCheckFolder\SqlServer" -ErrorAction SilentlyContinue).Path
                    $manualCheckFiles       = (Get-ChildItem -Path $manualCheckContainer | Where-Object { $_.name -like "*SQL*$version*Database*ManualChecks.psd1"}).basename
                }
                "SqlServerDatabase"
                {
                    $manualCheckContainer   = (Resolve-Path -Path "$manualCheckFolder\SqlServer" -ErrorAction SilentlyContinue).Path
                    $manualCheckFiles       = (Get-ChildItem -Path $manualCheckContainer | Where-Object { $_.name -like "*SQL*$version*Database*ManualChecks.psd1"}).basename
                }
            }
            
            if ("" -eq $stigFilePath)
            {
                $stigVersions           = $manualCheckFiles | Select-String "(\d+)R(\d+)" -AllMatches | Foreach-Object {$_.Matches.Value}
                $latestVersion          = ($stigVersions | Measure-Object -Maximum).Maximum
                $manualCheckFileName    = $manualCheckFiles | Where-Object { $_ -like "*$stigType*$latestVersion*" }
                $stigFilePath           = "$manualCheckContainer\$manualCheckFileName.psd1"
            }

        }
        "OrgSettings"
        {

            switch ($stigType)
            {
                "WindowsServer"
                {
                    $orgSettingsFiles   = (Get-ChildItem $orgSettingsFolder | Where-Object {$_.name -like "$stigType-$version-MS*"}).name
                }
                "DomainController"
                {
                    $orgSettingsFiles   = (Get-ChildItem $orgSettingsFolder | Where-Object {$_.name -like "WindowsServer-$version-DC*"}).name
                    $stigVersions           = $orgSettingsFiles | Select-String "(\d+)\.(\d+)" -AllMatches | Foreach-Object {$_.Matches.Value}
                    $latestVersion          = ($stigVersions | Measure-Object -Maximum).Maximum
                    $orgSettingsFileName    = $orgSettingsFiles | Where-Object {$_ -like "*WindowsServer*$latestVersion*.xml"}
                    $stigFilePath           = "$orgSettingsFolder\$orgSettingsFileName"
                }
                "WindowsClient"
                {
                    $orgSettingsFiles   = (Get-ChildItem $orgSettingsFolder | Where-Object { $_.name -Like "*$StigType*" }).name
                }
                "DotNetFramework"
                {
                    $orgSettingsFiles   = (Get-ChildItem $orgSettingsFolder | Where-Object { $_.name -like "$stigType-$version*"}).name
                }
                "InternetExplorer"
                {
                    $orgSettingsFiles   = (Get-ChildItem $orgSettingsFolder | Where-Object { $_.name -like "$stigType-$version*"}).name
                }
                "WebServer"
                {
                    $orgSettingsFiles   = (Get-ChildItem $orgSettingsFolder | Where-Object { $_.name -like "IISServer*$version*"}).name
                }
                "WebSite"
                {
                    $orgSettingsFiles   = (Get-ChildItem $orgSettingsFolder | Where-Object { $_.name -like "IISSite*$version*"}).name
                }
                "FireFox"
                {
                    $StigType           = "FireFox"
                    $orgSettingsFiles   = (Get-ChildItem $orgSettingsFolder | Where-Object { $_.name -like "$stigType-All-*"}).name
                }
                "Edge"
                {
                    $orgSettingsFiles   = (Get-ChildItem $orgSettingsFolder | Where-Object { $_.name -like "*$stigType*"}).name
                }
                "Chrome"
                {
                    $orgSettingsFiles   = (Get-ChildItem $orgSettingsFolder | Where-Object { $_.name -like "*$stigType*"}).name
                }
                "McAfee"
                {
                    $orgSettingsFiles   = (Get-ChildItem $orgSettingsFolder | Where-Object { $_.name -like "$stigType-$version*"}).name
                }
                "Office*"
                {
                    $officeApp      = $stigType.split('_')[1]
                    $officeVersion  = $stigType.split('_')[0].replace('Office','')
                    $orgSettingsFiles       = (Get-ChildItem "$orgSettingsFolder" | Where-Object { $_.name -like "*$officeApp$officeVersion*"}).name
                    $stigVersions           = $orgSettingsFiles | Select-String "(\d+)\.(\d+)" -AllMatches | Foreach-Object {$_.Matches.Value}
                    $latestVersion          = ($stigVersions | Measure-Object -Maximum).Maximum
                    $orgSettingsFileName    = $orgSettingsFiles | Where-Object { $_ -like "*$officeApp*$officeVersion*$latestVersion*.xml"}
                    $stigFilePath           = "$orgSettingsFolder\$orgSettingsFileName"
                }
                "OracleJRE"
                {
                    $orgSettingsFiles   = (Get-ChildItem $orgSettingsFolder | Where-Object { $_.name -like "$stigType-$version*"}).name
                }
                "WindowsDefender"
                {
                    $orgSettingsFiles   = (Get-ChildItem $orgSettingsFolder | Where-Object { $_.name -like "$stigType-$version*"}).name
                }
                "WindowsDefender"
                {
                    $orgSettingsFiles   = (Get-ChildItem $orgSettingsFolder | Where-Object { $_.name -like "$stigType-All*"}).name
                }
                "WindowsDNSServer"
                {
                    $orgSettingsFiles   = (Get-ChildItem $orgSettingsFolder | Where-Object { $_.name -like "$stigType*"}).name
                }
                "OracleJRE"
                {
                    $orgSettingsFiles   = (Get-ChildItem $orgSettingsFolder | Where-Object { $_.name -like "$stigType-$version"}).name
                }
                "AdobeReader"
                {
                    $orgSettingsFiles   = (Get-ChildItem $orgSettingsFolder | Where-Object { $_.name -like "Adobe-AcrobatReader-*"}).name
                }
            }

            if ($stigtype -like "WebSite*" -or $stigType -like "WebServer*")
            {
                $stigVersions           = $orgSettingsFiles | ForEach-Object { $_.split("-")[2] | Select-String "(\d+)\.(\d+)" -AllMatches | Foreach-Object {$_.Matches.Value} }
                $latestVersion          = ($stigVersions | Measure-Object -Maximum).Maximum
                $orgSettingsFileName    = $orgSettingsFiles | Where-Object { $_ -like "*$($stigType.replace("Web","IIS"))*$latestVersion*.xml"}
                $stigFilePath           = "$orgSettingsFolder\$orgSettingsFileName"
            }
            elseif ('' -eq $stigFilePath)
            {
                $stigVersions           = $orgSettingsFiles | Select-String "(\d+)\.(\d+)" -AllMatches | Foreach-Object {$_.Matches.Value}
                $latestVersion          = ($stigVersions | Measure-Object -Maximum).Maximum
                $orgSettingsFileName    = $orgSettingsFiles | Where-Object { $_ -like "*$stigType*$latestVersion*.xml"}
                $stigFilePath           = "$orgSettingsFolder\$orgSettingsFileName"
            }

        }
    }

    if ((Test-Path $stigFilePath) -and ( $stigFilePath -like "*.xml" -Or $stigFilePath -like "*.psd1") )
    {
        return $stigFilePath
    }
    elseif ($stigtype -notlike "*SQL*")
    {
        Write-Warning "$NodeName - Unable to find $fileType file for $stigType STIG."
        return $null
    }
}

function Test-Connections
{
    [cmdletbinding()]
    param(

        [Parameter()]
        [string]
        $RootPath = (Get-Location).Path,

        [Parameter()]
        [string]
        $NodeDataPath = (Resolve-Path -Path "$Rootpath\*NodeData").Path,

        [Parameter()]
        [array]
        $TargetMachines = @(Get-Childitem -Path "$nodeDataPath\*.psd1" -Recurse | Where-Object { $_.FullName -notlike "*staging*" })

   )

    $stagingPath = "$NodeDataPath\Staging"

    if ((Test-Path $stagingPath) -eq $False )
    {
        New-Item $stagingPath -Itemtype Directory -Force
    }

    foreach ($server in $TargetMachines)
    {
        Write-Output "Testing connections on $($server.basename)."
        $pingTest = (Test-NetConnection $server.basename -WarningAction SilentlyContinue -ErrorAction SilentlyContinue).PingSucceeded

        if ($pingTest -eq $true)
        {
            $pingSuccesses += $server.basename
            Write-Output "`tPing Succeeded."
            $winRMTest = Test-WSMan -Computername $server.basename -Authentication Default -ErrorAction SilentlyContinue -WarningAction SilentlyContinue

            if ($null -ne $winRMTest)
            {
                Write-Output "`tWinRM Test Passed."
            }
            else
            {
                Write-Output "`tWinRM Test Failed. Moving configdata file to Staging Folder."
                Move-Item $server.fullname -Destination $stagingPath
            }
        }
        else
        {
            Write-Output "`tPing Failed. Moving Configdata file to Staging Folder."
            Move-Item $server.Fullname -Destination $stagingPath
        }
    }
}

function Get-ApplicableStigs
{
    [cmdletbinding()]
    param(

        [Parameter()]
        [string]
        $RootPath = (Get-Location).Path,

        [Parameter()]
        [string]
        $Computername = $env:COMPUTERNAME,

        [Parameter()]
        [switch]
        $LocalHost

   )

   Write-Output "`t`tGathering STIG Applicability for $ComputerName"

   # Get Windows Version from Active Directory
    if ($LocalHost)
    {
        $WindowsVersion = 10
        $ComputerName = 'LocalHost'
    }
    else
    {
        $windowsVersion = (Get-ADComputer -Identity $computername -Properties OperatingSystem).OperatingSystem
    }

    $windowsVersion         = (Get-ADComputer -Identity $computername -Properties OperatingSystem).OperatingSystem
    $applicableSTIGs        = @("InternetExplorer","DotnetFramework")

    try {
        # Get Installed Software from Target System
        $installedSoftware = Invoke-Command -ComputerName $ComputerName -ErrorAction Stop -Scriptblock {
            $localSoftwareList = @(Get-ItemProperty "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" | Select-Object DisplayName, DisplayVersion, Publisher, InstallDate)
            $localSoftwareList += @(Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" | Select-Object DisplayName, DisplayVersion, Publisher, InstallDate)
            return $localSoftwareList
        }

        # Get Installed Roles on Target System
        if ($windowsVersion -notlike "*Windows 10*")
        {
            $installedRoles = Invoke-Command -ComputerName $ComputerName -Erroraction Stop -Scriptblock {
                $localRoleList = @(Get-WindowsFeature | Where { $_.Installed -eq $True })
                return $localRoleList
            }
        }
    }
    catch
    {
        Write-Warning "Unable to determine STIG Applicability for $ComputerName. Please verify WinRM connectivity."
    }

    switch -Wildcard ($installedSoftware.DisplayName)
    {
        "*Adobe Acrobat Reader*"    {$applicableStigs += "AdobeReader"}
        "*McAfee*"                  {$applicableStigs += "McAfee"}
        "*Office*16*"               {$applicableStigs += "Office2016"}
        "*Office*15*"               {$applicableStigs += "Office2013"}
        "*FireFox*"                 {$applicableStigs += "FireFox"}
        "*Chrome*"                  {$applicableStigs += "Chrome"}
        "*Edge*"                    {$applicableStigs += "Edge"}
        "*OracleJRE*"               {$applicableStigs += "OracleJRE"}
        "Microsoft SQL Server*"     {$applicableStigs += "SqlServerInstance","SqlServerDatabase"}
    }

    switch -WildCard ($installedRoles.Name)
    {
        "Web-Server"
        {
            $iisVersion = Invoke-Command -ComputerName $Computername -Scriptblock {
                $iisData = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\InetStp"
                $localIisVersion = "$($iisData.MajorVersion).$($iisData.MinorVersion)"
                return $localiisVersion
            }
            $applicableStigs += "WebServer-$IISVersion","Website-$IISVersion"
        }
        "Windows-Defender"      {$applicableStigs += "WindowsDefender","WindowsFirewall"}
        "DNS"                   {$applicableStigs += "WindowsDnsServer"}
        "AD-Domain-Services"    {$applicableStigs += "ActiveDirectory"}
    }

    switch -WildCard ($windowsVersion)
    {
        "*2012*"    {$applicableSTIGs += "WindowsServer-2012R2-MemberServer"}
        "*2016*"    {$applicableSTIGs += "WindowsServer-2016-MemberServer"}
        "*2019*"    {$applicableSTIGs += "WindowsServer-2019-MemberServer"}
        "*10*"      {$applicableSTIGs += "WindowsClient"}
    }

    $applicableStigs = $applicableStigs | Select-Object -Unique
    return $applicableStigs
}

function Get-DscComplianceReports
{
    [cmdletbinding()]
    param(

        [Parameter()]
        [string]
        $RootPath = (Get-Location).Path,

        [Parameter()]
        [string]
        $MofPath = (Resolve-Path -Path "$RootPath\*Artifacts\Mofs").Path,

        [Parameter()]
        [string]
        $LogsPath = (Resolve-Path -Path "$Rootpath\*Artifacts\Logs").Path,

        [Parameter()]
        [string]
        $OutputPath = (Resolve-Path -Path "$Rootpath\*Artifacts\Reports").Path,

        [Parameter()]
        [array]
        $DscResults
   )
    if ($DSCResults.count -lt 1)
    {
        $DscResults = Test-DSCConfiguration -Path $MofPath
    }

    $DscResults | Export-Clixml -Path "$OutputPath\DscResults.xml" -Force

    $results = Import-CliXml "$OutputPath\DscResults.xml"
    $newdata = $results | ForEach-Object {
        if ($_.ResourcesInDesiredState)
        {
            $_.ResourcesInDesiredState | ForEach-Object {
                $_
            }
        }
        if ($_.ResourcesNotInDesiredState)
        {
            $_.ResourcesNotInDesiredState | ForEach-Object {
                $_
            }
        }
    }
    $parsedData = $newdata | Select-Object PSComputerName, ResourceName, InstanceName, InDesiredState, ConfigurationName, StartDate
    $parsedData | Export-Csv -Path $OutputPath\DscResults.csv -NoTypeInformation
}

function Get-OuDN
{

    [CmdletBinding()]
    param
    (
        [Parameter()]
        [string]
        $ComputerName = "$env:computername"

    )

    $dn = (Get-AdComputer -Identity $ComputerName).DistinguishedName
    return $dn.replace("CN=$Env:ComputerName,","")
}

function Clear-NodeData
{
    [CmdletBinding()]
    param (
        [Parameter()]
        [String]
        $Rootpath = (Get-Location).Path
    )

    $nodeDataPath = (Resolve-Path -Path "$RootPath\*NodeData").Path
    $ConfigDataFiles = Get-Childitem $nodeDataPath -Recurse | Where-Object { $_.FullName -Notlike "*Staging*" }

    Write-Output "`tRemoving $($configDataFiles.count) DSC COnfigData Files"
    Remove-Item $configDataFiles.FullName -Force -Confirm:$False -Recurse
}

function Get-ManualCheckFileFromXccdf
{
    [cmdletBinding()]
    param (

        [Parameter()]
        [string]
        $XccdfPath,

        [Parameter()]
        [string]
        $ManualCheckPath = ".\Resources\ManualChecks\New"
    )

    foreach ($path in $XccdfPath)
    {
        $file           = Get-Item $path
        [xml]$content   = Get-Content -path $file -Encoding UTF8
        $split          = $file.basename.split("_")
        $StigType       = $split[1]
        $subType        = $split[2] + $split[3] + $split[4] + $split[5]
        $Vuls           = $content.benchmark.group.id
        $outfileName    = "$subType-manualchecks.psd1"

        $manualCheckContent = @()
        foreach ($vul in $vuls)
        {
            $manualCheckContent += "@{"
            $manualCheckContent += "    VulID       = `"$vul`""
            $manualCheckContent += "    Status      = `"NotReviewed`""
            $manualCheckContent += "    Comments    = `"Input Finding Comments`""
            $manualCheckContent += "}`n"
        }
        $manualCheckContent | Out-File "$manualCheckPath\$outFileName" -force
    }
}

function Publish-SCARArtifacts {

    Param (
        [string]$repoUrl,
        [string]$repoName,
        [string]$repoFolderLocation,
        [string]$pathOfFolderToCopy,
        [string]$accessToken,
        [string]$targetPath
    )
    $env:GIT_REDIRECT_STDERR = '2>&1'
    $startingPath = (Get-Location).Path
    Write-Host "Checking out $repoUrl."

    if($accessToken.Length -gt 0) {git clone $repoUrl -c http.extraheader="AUTHORIZATION: bearer $accessToken" -v}
    else {git clone $repoUrl -v}

    if(Test-Path $pathOfFolderToCopy){$publishArtifacts = Get-Item $pathOfFolderToCopy}
    else {Write-Host "Invalid Path Of Folder Copy Location: $pathOfFolderToCopy";exit}

    if(Test-Path $repoFolderLocation){Set-Location $repoFolderLocation}
    else {Write-Host "Invalid Folder Repo Location: $repoFolderLocation";exit}

    $sourcePath     = $publishArtifacts.FullName+"\*"
    if (Test-Path $targetPath) {Remove-Item $targetPath -Recurse -Force}
    if(!(Test-Path $targetPath)) {New-Item -Path $targetPath -ItemType Directory}

    Copy-Item $sourcePath $targetPath -Recurse -Force
    git config --global user.email "SYSTEM@CONTOSO.COM"
    git config --global user.name "SYSTEM"
    git add --all
    git commit -m "Automated Commit"
    git push
    cd $startingPath

    if(Test-Path $repoName){
        Remove-Item $repoName -Recurse -Force
    }
}

#region Stig Checklist Functions
function Get-StigChecklists
{
    <#

    .SYNOPSIS
    This function will generate the STIG Checklists and output them to the Reports directory under SCAR.

    .PARAMETER Rootpath
    Path to the root of the SCAR repository/codebase.
    C:\Your Repo\SCAR\

    .PARAMETER OutputPath
    Path of where the checklists will be generated. Defaults to:
    Artifacts\Stig Checklist

    .PARAMETER TargetMachines
    List of target machines. If not specificied, a list will be generated from configurations present in "C:\Your Repo\SCAR\NodeData"

    .PARAMETER TestConfig
    Switch parameter that allows testing against the configuration and the target machine. If switch is used, it will run test-dscconfiguration for the mof against the target machines to verify compliance.

    .EXAMPLE
    Example Get-StigChecklists -RootPath "C:\Your Repo\SCAR\"

    .EXAMPLE
    Example Get-StigChecklists -RootPath "C:\Your Repo\SCAR\" -TestConfig

    #>

    [cmdletbinding()]
    param(

        [Parameter()]
        [string]
        $RootPath = (Get-Location).Path,

        [Parameter()]
        [string]
        $OutputPath,

        [Parameter()]
        [array]
        $TargetMachines,

        [Parameter()]
        [string]
        $TargetFolder,

        [Parameter()]
        [string]
        $checklistDataPath,

        [Parameter()]
        [switch]
        $MofSettings,

        [Parameter()]
        [switch]
        $GenerateReports,

        [Parameter()]
        [switch]
        $LocalHost,

        [Parameter()]
        [string]
        $Enclave = "Unclassified"

    )

    # Initialize File Paths
    $nodeDataPath       = (Resolve-Path -Path "$RootPath\*NodeData").path
    $mofPath            = (Resolve-Path -Path "$RootPath\*Artifacts\Mofs").path
    $resourcePath       = (Resolve-Path -Path "$RootPath\*Resources").path
    $artifactsPath      = (Resolve-Path -Path "$RootPath\*Artifacts").path
    $cklContainer       = (Resolve-Path -Path "$artifactsPath\STIG Checklists").Path
    $allCkls            = @()

    if (-not ($LocalHost))
    {
        if ($null -eq $TargetMachines)
        {
            if ('' -eq $TargetFolder)
            {
                $targetMachines = (Get-Childitem -Path $nodeDataPath -recurse | Where-object {$_.FullName -like "*.psd1" -and $_.fullname -notlike "*staging*"}).basename
            }
            else
            {
                if (Test-Path "$nodeDataPath\$TargetFolder")
                {
                    $targetMachines = (Get-Childitem -Path "$nodeDataPath\$TargetFolder\*.psd1" -recurse).basename
                }
                else
                {
                    Write-Output "$TargetFolder is not a valid nodedata subfolder. Please verify the folder name."
                    end
                }
            }
        }
    }
    else
    {
        $targetMachines = @("$env:ComputerName")
    }

    $dscResults = @()
    $jobs = @()
    Write-Output "`tStarting STIG Checklist generation jobs for $($targetMachines.count) targetted machines.`n"
    foreach ($machine in $targetMachines)
    {
        if (-not (Test-Path "$cklContainer\$machine"))
        {
            $machineFolder = (New-Item -Path $CklContainer -Name "$machine" -ItemType Directory -Force).FullName
        }
        else
        {
            $machineFolder = "$cklContainer\$machine"
        }

        Write-Output "`t`tStarting Job - Generate STIG Checklists for $machine"

        $job = Start-Job -InitializationScript {Import-Module -Name "C:\Program Files\WindowsPowershell\Modules\PowerSTIG\*\powerstig.psm1","C:\Program Files\WindowsPowershell\Modules\DSCSM\*\DSCSM.psm1"} -Scriptblock {

            $machine            = $using:machine
            $RootPath           = $using:RootPath
            $machineFolder      = $using:machinefolder
            $nodeDataPath       = (Resolve-Path -Path "$RootPath\*NodeData").path
            $mofPath            = (Resolve-Path -Path "$RootPath\*Artifacts\Mofs").path
            $resourcePath       = (Resolve-Path -Path "$RootPath\*Resources").path
            $artifactsPath      = (Resolve-Path -Path "$RootPath\*Artifacts").path
            $cklContainer       = (Resolve-Path -Path "$artifactsPath\STIG Checklists").Path
            $nodeDataFile       = (Resolve-Path -Path "$nodeDataPath\*\$machine.psd1").path
            $data               = Invoke-Expression (Get-Content $NodeDataFile | Out-String)
            $osVersion          = (Get-WmiObject Win32_OperatingSystem).caption | Select-String "(\d+)([^\s]+)" -AllMatches | Foreach-Object {$_.Matches.Value}
            $dscResult          = $null
            $remoteCklJobs      = @()

            Write-Output "`n`n`t`t$Machine - Begin STIG Checklist Generation`n"

            if ($null -ne $data.appliedConfigurations)  {$appliedStigs = $data.appliedConfigurations.getenumerator() | Where-Object {$_.name -like "POWERSTIG*"}}
            if ($null -ne $data.manualStigs)            {$manualStigs  = $data.manualStigs.getenumerator()}

            if ($null -ne $appliedStigs)
            {
                $winRmTest  = Test-WSMan -Computername $machine -Authentication Default -Erroraction silentlycontinue
                $ps5check   = Invoke-Command -ComputerName $machine -ErrorAction SilentlyContinue -Scriptblock {return $psversiontable.psversion.major}

                if ($null -eq $winRmTest)
                {
                    Write-Warning "`t`t`tUnable to connect to $machine to Test DSC Compliance. Verify WinRM connectivity."
                    Continue
                }

                if ($ps5Check -lt 5)
                {
                    Write-Warning "The Powershell version on $machine does not support Desired State Configuration. Minimum Powershell version is 5.0"
                    Continue
                }

                try
                {
                    if ($machine -eq $env:computername)
                    {
                        $referenceConfiguration = (Resolve-Path "$mofPath\*$machine.mof").Path
                        $null = New-Item "C:\ScarData\STIG Data\ManualChecks" -ItemType Directory -Force -Confirm:$False
                        $null = New-Item "C:\ScarData\STIG Data\Xccdfs" -ItemType Directory -Force -Confirm:$False
                        $null = New-Item "C:\ScarData\STIG Checklists" -ItemType Directory -Force -Confirm:$False
                        $null = New-Item "C:\ScarData\MOF" -ItemType Directory -Force -Confirm:$False
                        $null = Copy-Item -Path $referenceConfiguration -Destination "C:\SCARData\MOF\" -Force -Confirm:$False                       
                    }
                    else 
                    {
                        $referenceConfiguration = (Resolve-Path "$mofPath\*$machine.mof").Path
                        $null = New-Item "\\$machine\c$\SCAR\STIG Data\ManualChecks" -ItemType Directory -Force -Confirm:$False
                        $null = New-Item "\\$machine\c$\SCAR\STIG Data\Xccdfs" -ItemType Directory -Force -Confirm:$False
                        $null = New-Item "\\$machine\c$\SCAR\STIG Checklists" -ItemType Directory -Force -Confirm:$False
                        $null = New-Item "\\$machine\c$\SCAR\MOF" -ItemType Directory -Force -Confirm:$False
                        $null = Copy-Item -Path $referenceConfiguration -Destination "\\$machine\c$\SCAR\MOF\" -Force -Confirm:$False         
                    }

                    $directoryCopy = $true
                }
                catch
                {
                    Write-Output "`t`t`t`tUnable to Copy SCAR directory to $Machine."
                    $directoryCopy = $false
                }
                
                if ($directoryCopy)
                {
                    $attemptCount = 0 

                    do 
                    {
                        try
                        {
                            $attemptCount++
                            Write-Output "`t`tExecuting remote DSC Compliance Scan (Attempt $attemptCount/5)"
                            if ($machine -eq $env:computername)
                            {
                                $dscResult = Test-DscConfiguration -ReferenceConfiguration $ReferenceConfiguration -ErrorAction Continue
                            }
                            else
                            {
                                $dscResult  = Invoke-Command -Computername $machine -ErrorAction Stop -Scriptblock {
                                    Test-DscConfiguration -ReferenceConfiguration "C:\SCAR\MOF\$env:Computername.mof"
                                }
                            }

                            $remoteExecution = $true
                        }
                        catch 
                        {
                            if ($machine -eq $env:computername)
                            {
                                Stop-DscConfiguration -force -erroraction SilentlyContinue -WarningAction SilentlyContinue
                            }
                            else
                            {
                                Invoke-Command -ComputerName $machine -erroraction SilentlyContinue -WarningAction SilentlyContinue -Scriptblock {
                                    Stop-DscConfiguration -force -erroraction SilentlyContinue -WarningAction SilentlyContinue
                                }
                            }
                            Start-Sleep -Seconds 5
                            $remoteExecution = $False
                        }
                    }
                    until ($null -ne $dscResult -or $attemptCount -ge 5)
                }
                elseif ($directoryCopy -eq $false)
                {
                    Write-Warning "`t`tRemote Execution failed - Attempting compliance scan locally (Attempt $attemptCount/5)"
                    $attemptCount   = 0
                    do
                    {
                        try
                        {
                            $attemptCount++
                            $referenceConfiguration = (Resolve-Path "$mofPath\*$machine.mof").Path
                            Write-Output "`t`t`tExecuting local DSC Compliance Scan (Attempt $attemptCount/5)"

                            if (Test-Path -Path $referenceConfiguration)
                            {
                                $dscResult = Test-DscConfiguration -Computername $machine -ReferenceConfiguration $referenceConfiguration -ErrorAction Stop
                            }
                            else
                            {
                                Write-Output "`t`t`t`tNo MOF exists for $machine."
                                Continue
                            }
                        }
                        catch
                        {
                            Write-Output "`t`t`t`tError gathering DSC Status. Restarting DSC Engine and trying again in 5 Seconds."
                            if ($machine -eq $env:computername)
                            {
                                Stop-DscConfiguration -force -erroraction SilentlyContinue -WarningAction SilentlyContinue
                            }
                            else
                            {
                                Invoke-Command -ComputerName $machine -erroraction SilentlyContinue -WarningAction SilentlyContinue -Scriptblock {
                                    Stop-DscConfiguration -force -erroraction SilentlyContinue -WarningAction SilentlyContinue
                                }
                            }
                            Start-Sleep -Seconds 5
                        }
                    }
                    until ($null -ne $dscResult -or $attemptCount -ge 5)
                    
                    if ($null -eq $dscResult)
                    {
                        Write-Output "Unable to execute compliance scan on $machine. Please verify winrm connectivity."
                        exit
                    }
                }
 
                foreach ($stig in $appliedStigs)
                {

                    $stigType       = $stig.name.tostring().replace("PowerSTIG_", "")
                    $cklPath        = "$machineFolder\$machine-$stigType.ckl"

                    if (($null -ne $stig.Value.XccdfPath) -and (Test-Path $stig.Value.XccdfPath))
                    {
                        $xccdfPath = $stig.Value.XccdfPath
                    }
                    else 
                    {
                        Write-Warning "$machine - No xccdf file provided for $Stigtype"
                        continue
                    }

                    if (($null -ne $stig.value.ManualChecks) -and (Test-Path $stig.Value.ManualChecks))
                    {
                        $manualCheckFile = $stig.Value.ManualChecks
                    }
                    else
                    {
                        Write-Verbose "$machine - No Manual Check file provided for $Stigtype"
                    }

                    if ($remoteExecution)
                    {
                        Write-Output "`t`t`tSTIG Checklist - $stigType"
                        $remoteXccdfPath        = (Copy-Item -Path $xccdfPath -Passthru -Destination "\\$machine\C$\Scar\STIG Data\Xccdfs" -Container -Force -Confirm:$False).fullName.Replace("\\$machine\C$\","C:\")
                        $remoteCklPath          = "C:\SCAR\STIG Checklists"

                        if ($null -ne $manualCheckFile)
                        {
                            $remoteManualCheckFile  = (Copy-Item -Path $ManualCheckFile -Passthru -Destination "\\$machine\C$\Scar\STIG Data\Xccdfs" -Container -Force -Confirm:$False).FullName.Replace("\\$machine\C$\","C:\")
                        }
                        
                        $remoteCklJob = Invoke-Command -ComputerName $machine -AsJob -ArgumentList $remoteXccdfPath,$remoteManualCheckFile,$remoteCklPath,$dscResult,$machineFolder,$stigType -ScriptBlock {
                            param(
                                [Parameter(Position=0)]$remoteXccdfPath,
                                [Parameter(Position=1)]$remoteManualCheckFile,
                                [Parameter(Position=2)]$remoteCklPath,                                
                                [Parameter(Position=3)]$dscResult,
                                [Parameter(Position=4)]$machineFolder,
                                [Parameter(Position=5)]$stigType
                            )
                            Import-Module -Name "C:\Program Files\WindowsPowershell\Modules\PowerSTIG\*\powerstig.psm1"
                            Import-Module -Name "C:\Program Files\WindowsPowershell\Modules\DSCSM\*\DSCSM.psm1"

                            $params = @{
                                xccdfPath       = $remotexccdfPath
                                OutputPath      = "$remoteCklPath\$env:computername-$stigType.ckl"
                                DscResult       = $dscResult
                                Enclave         = $Enclave
                            }
                            if ($null -ne $remoteManualCheckFile) 
                            {
                                $params += @{ManualCheckFile = $remoteManualCheckFile}
                            }
                            Get-StigChecklist @params -ErrorAction SilentlyContinue
                        }
                        $remoteCklJobs += $remoteCklJob
                    }
                    else
                    {
                        Write-Output "`t`t`tSTIG Checklist - $stigType"
                        $params = @{
                            xccdfPath       = $xccdfPath
                            outputPath      = $cklPath
                            DSCResult       = $dscResult
                            Enclave         = $Enclave
                        }
                        if ($null -ne $ManualCheckFile) 
                        {
                            $params += @{ManualCheckFile = $ManualCheckFile}
                        }
                        Get-StigChecklist @params -ErrorAction SilentlyContinue
                    }
                }
            }

            if ($null -ne $manualStigs)
            {
                foreach ($manStig in $manualStigs)
                {

                    if ($null -ne $manStig.Value.Subtypes)
                    {
                        $stigType = $manStig.name.tostring().replace("StigChecklist_", "")
                        $subTypes = $manStig.value.subTypes

                        foreach ($subType in $subTypes)
                        {
                            Write-Output "`t`tGenerating Checklist - $StigType-$subtype"
                            $manCheckFileHint   = $subtype.replace("_","")
                            $xccdfHint          = $subtype
                            $manualCheckFile    = (Get-Childitem "$rootpath\Resources\Stig Data\Manual Checks\$stigType\*.psd1"      | Where {$_.name -like "*$manCheckFileHint*"}).FullName
                            $xccdfPath          = (Get-Childitem "$rootpath\Resources\Stig Data\XCCDFs\$stigType\*Manual-xccdf.xml"  | Where {$_.name -like "*$xccdfHint*"}).FullName
                            $cklPath            = "$machineFolder\$machine-$stigType_$manCheckFileHint.ckl"

                            $params = @{
                                xccdfPath       = $xccdfPath
                                OutputPath      = $cklPath
                                ManualCheckFile = $manualCheckFile
                                NoMof           = $true
                                NodeName        = $data.nodename
                                Enclave         = $Enclave
                            }
                            Get-StigChecklist @params -ErrorAction SilentlyContinue
                        }
                    }
                    elseif ($null -ne $manstig.name)
                    {
                        $stigType           = $manStig.name.tostring().replace("StigChecklist_", "")
                        Write-Output "`t`tGenerating Checklist - $stigType"
                        $manualCheckFile    = (Get-Childitem "$rootpath\Resources\Stig Data\Manual Checks\$stigType\*.psd1"     | Select -first 1).FullName
                        $xccdfPath          = (Get-Childitem "$rootpath\Resources\Stig Data\XCCDFs\$stigType\*Manual-xccdf.xml" | Select -first 1).FullName
                        $cklPath            = "$machineFolder\$machine-$stigType.ckl"
                        $params = @{
                            xccdfPath       = $xccdfPath
                            OutputPath      = $cklPath
                            ManualCheckFile = $manualCheckFile
                            NoMof           = $true
                            NodeName        = $data.nodename
                            Enclave         = $Enclave
                        }
                        Get-StigChecklist @params -ErrorAction SilentlyContinue
                    }
                    else
                    {
                        Write-Output "Unable to generate $stigtype STIG Checklist for $machine. Please verify that STIG Data files."
                        Continue
                    }
                }
            }
            
            if ($remoteCklJobs.count -gt 0)
            {
                Get-Job -ID $remoteCklJobs.ID | Wait-Job | Receive-Job
                Get-Job -ID $remoteCklJobs.ID | Remove-Job
                $remoteCkls = Get-Childitem -Path "\\$machine\C$\SCAR\STIG Checklists\*.ckl" -Recurse
                Copy-Item -Path $remoteCkls.FullName -Destination $machineFolder
            }

            $machineCkls = (Get-ChildItem "$machineFolder\*.ckl" -recurse).count

            if ($machineCkls -lt 1)
            {
                Remove-Item $machineFolder -Force -Recurse -Confirm:$False
            }
            Write-Output "`t`t$machine - STIG Checklist job complete"
        }
        $jobs += $job.id
    }
    Write-Output "`n`tJob creation for STIG Checklists Generation is Complete. Waiting for $($jobs.count) jobs to finish processing"
    Get-Job -ID $jobs | Wait-Job | Receive-Job

    $cklCount = (Get-ChildItem "$cklContainer\*.ckl" -Recurse).count
    Write-Output "`tSTIG Checklist generation complete. Total STIG Checklists generated - $cklCount`n"
    Get-Job -ID $jobs | Remove-Job
}

function Get-StigCheckList
{
    <#
    .SYNOPSIS
        Automatically creates a Stig Viewer checklist from the DSC results or
        compiled MOF

    .PARAMETER ReferenceConfiguration
        The MOF that was compiled with a PowerStig composite

    .PARAMETER DscResult
        The results of Test-DscConfiguration

    .PARAMETER XccdfPath
        The path to the matching xccdf file. This is currently needed since we
        do not pull add xccdf data into PowerStig

    .PARAMETER OutputPath
        The location you want the checklist saved to

    .PARAMETER ManualCheckFile
        Location of a psd1 file containing the input for Vulnerabilities unmanaged via DSC/PowerSTIG.

    .EXAMPLE
        Get-StigChecklist -ReferenceConfiguration $referenceConfiguration -XccdfPath $xccdfPath -OutputPath $outputPath

    .EXAMPLE
        Get-StigChecklist -ReferenceConfiguration $referenceConfiguration -ManualCheckFile "C:\Stig\ManualChecks\2012R2-MS-1.7.psd1" -XccdfPath $xccdfPath -OutputPath $outputPath
        Get-StigChecklist -ReferenceConfiguration $referenceConfiguration -ManualCheckFile $manualCheckFilePath -XccdfPath $xccdfPath -OutputPath $outputPath
    #>
    [CmdletBinding()]
    [OutputType([xml])]
    param
    (
        [Parameter(Mandatory = $true, ParameterSetName = 'mof')]
        [string]
        $ReferenceConfiguration,

        [Parameter(Mandatory = $true, ParameterSetName = 'result')]
        [psobject]
        $DscResult,

        [Parameter(Mandatory = $true, ParameterSetName = 'noMof')]
        [switch]
        $NoMof,

        [Parameter(Mandatory = $true, ParameterSetName = 'noMof')]
        [string]
        $NodeName,

        [Parameter(Mandatory = $true)]
        [string]
        $XccdfPath,

        [Parameter(Mandatory = $true)]
        [string]
        $OutputPath,

        [Parameter()]
        [string]
        $ManualCheckFile,

        [Parameter()]
        [string]
        $Enclave = "Unclassified"
    )

    # Validate parameters before continuing
    if ($ManualCheckFile)
    {
        if (-not (Test-Path -Path $ManualCheckFile))
        {
            throw "$($ManualCheckFile) is not a valid path to a ManualCheckFile. Provide a full valid path"
        }

        $parent = Split-Path $ManualCheckFile -Parent
        $filename = Split-Path $ManualCheckFile -Leaf
        $manualCheckData = Import-LocalizedData -BaseDirectory $parent -Filename $fileName
    }

    # Values for some of these fields can be read from the .mof file or the DSC results file
    if ($PSCmdlet.ParameterSetName -eq 'mof')
    {
        if (-not (Test-Path -Path $ReferenceConfiguration))
        {
            throw "$($ReferenceConfiguration) is not a valid path to a configuration (.mof) file. Please provide a valid entry."
        }

        $MofString = Get-Content -Path $ReferenceConfiguration -Raw
        $TargetNode = Get-TargetNodeFromMof($MofString)

    }
    elseif ($PSCmdlet.ParameterSetName -eq 'result')
    {
        # Check the returned object
        if ($null -eq $DscResult)
        {
            throw 'Passed in $DscResult parameter is null. Please provide a valid result using Test-DscConfiguration.'
        }
        $TargetNode = $DscResult.PSComputerName
    }
    elseif ($PSCmdlet.ParameterSetName -eq 'NoMof')
    {
        $nodeDataFile   = (Resolve-Path "$RootPath\NodeData\*\$machine*").path
        $nodeData       = Invoke-Expression (Get-Content $NodeDataFile | Out-String)
        $targetNode     = $NodeName
    }
    $TargetNodeType = Get-TargetNodeType($TargetNode)

    switch ($TargetNodeType)
    {
        "MACAddress"
        {
            $HostnameMACAddress = $TargetNode
            Break
        }
        "IPv4Address"
        {
            $HostnameIPAddress = $TargetNode
            Break
        }
        "IPv6Address"
        {
            $HostnameIPAddress = $TargetNode
            Break
        }
        "FQDN"
        {
            $HostnameFQDN = $TargetNode
            Break
        }
        default
        {
            $Hostname = $TargetNode
        }
    }

    $xmlWriterSettings = [System.Xml.XmlWriterSettings]::new()
    $xmlWriterSettings.Indent = $true
    $xmlWriterSettings.IndentChars = "`t"
    $xmlWriterSettings.NewLineChars = "`n"
    $writer = [System.Xml.XmlWriter]::Create($OutputPath, $xmlWriterSettings)

    $writer.WriteStartElement('CHECKLIST')

    #region ASSET

    $writer.WriteStartElement("ASSET")
    try 
    {
        $macAddress = Invoke-Command $hostname -ErrorAction Stop -scriptblock { 
            $macs = (get-netadapter | Where {$_.status -eq "Up"} | select macaddress).macaddress 
            if ( $macs.count -gt 1 ) { $serverMac = $macs[0] }
            else { $serverMac = $macs }
            return $ServerMac
        } 
        
        $ipAddress  = Invoke-Command $hostname -ErrorAction Stop -scriptblock { 
            $serverIPs = ( get-netipaddress -addressFamily ipv4 | where { $_.IpAddress -notlike "127.*" } ).IPAddress
            if ( $serverIPs.count -gt 1 ) { $serverIP = $ServerIps[0] }
            else { $serverIP = $serverIPs }
            return $serverIP
        }

        $FQDN       = ( Get-ADComputer $hostName -ErrorAction Stop).DnsHostName
    }
    catch
    {
        if (-not $PSCmdlet.ParameterSetName -eq 'NoMof')
        {
            Write-Warning -Message "Error obtaining host data for $hostname."
        }
    }

    $assetElements = [ordered] @{
        'ROLE'            = 'Member Server'
        'ASSET_TYPE'      = 'Computing'
        'HOST_NAME'       = "$Hostname"
        'HOST_IP'         = "$IPAddress"
        'HOST_MAC'        = "$MACAddress"
        'HOST_FQDN'       = "$FQDN"
        'TECH_AREA'       = ''
        'TARGET_KEY'      = '2350'
        'WEB_OR_DATABASE' = 'false'
        'WEB_DB_SITE'     = ''
        'WEB_DB_INSTANCE' = ''
    }

    foreach ($assetElement in $assetElements.GetEnumerator())
    {
        $writer.WriteStartElement($assetElement.name)
        $writer.WriteString($assetElement.value)
        $writer.WriteEndElement()
    }

    $writer.WriteEndElement(<#ASSET#>)

    #endregion ASSET

    $writer.WriteStartElement("STIGS")
    $writer.WriteStartElement("iSTIG")

    #region STIGS/iSTIG/STIG_INFO

    $writer.WriteStartElement("STIG_INFO")

    $xccdfBenchmarkContent = Get-StigXccdfBenchmarkContent -Path $xccdfPath

    $stigInfoElements = [ordered] @{
        'version'        = $xccdfBenchmarkContent.version
        'classification' = "$Enclave"
        'customname'     = ''
        'stigid'         = $xccdfBenchmarkContent.id
        'description'    = $xccdfBenchmarkContent.description
        'filename'       = Split-Path -Path $xccdfPath -Leaf
        'releaseinfo'    = $xccdfBenchmarkContent.'plain-text'.InnerText
        'title'          = $xccdfBenchmarkContent.title
        'uuid'           = (New-Guid).Guid
        'notice'         = $xccdfBenchmarkContent.notice.InnerText
        'source'         = $xccdfBenchmarkContent.reference.source
    }

    foreach ($StigInfoElement in $stigInfoElements.GetEnumerator())
    {
        $writer.WriteStartElement("SI_DATA")

        $writer.WriteStartElement('SID_NAME')
        $writer.WriteString($StigInfoElement.name)
        $writer.WriteEndElement(<#SID_NAME#>)

        $writer.WriteStartElement('SID_DATA')
        $writer.WriteString($StigInfoElement.value)
        $writer.WriteEndElement(<#SID_DATA#>)

        $writer.WriteEndElement(<#SI_DATA#>)
    }

    $writer.WriteEndElement(<#STIG_INFO#>)

    #endregion STIGS/iSTIG/STIG_INFO

    #region STIGS/iSTIG/VULN[]

    # Pull in the processed XML file to check for duplicate rules for each vulnerability
    [xml]$xccdfBenchmark = Get-Content -Path $xccdfPath -Encoding UTF8
    $fileList = Get-PowerStigFileList -StigDetails $xccdfBenchmark
    if ($XccfdPath -like "*2016*")
    {
        $processedFolder    = "C:\Program Files\WindowsPowerShell\Modules\PowerSTIG\4.5.1\StigData\Processed"
        $processedXccdfs    = (Get-ChildItem $processedFolder | Where { $_.name -like "*WindowsServer*2016*MS*xml"}).name
        $latestVersion      = ($Versions | Measure-Object -Maximum ).maximum
        $processedFile      = (Resolve-Path "$processedFolder\$($processedXccdfs | Where { $_ -like "*$latestVersion*" })").path
    }
    else
    {
        $processedFileName = $fileList.Settings.FullName
    }
    #[xml]$processed = Get-Content -Path $processedFileName
    $vulnerabilities = Get-VulnerabilityList -XccdfBenchmark $xccdfBenchmarkContent

    foreach ($vulnerability in $vulnerabilities)
    {
        $writer.WriteStartElement("VULN")

        foreach ($attribute in $vulnerability.GetEnumerator())
        {
            $status         = $null
            $findingDetails = $null
            $comments       = $null
            $manualCheck    = $null

            if ($attribute.Name -eq 'Vuln_Num')
            {
                $vid = $attribute.Value
            }

            $writer.WriteStartElement("STIG_DATA")
            $writer.WriteStartElement("VULN_ATTRIBUTE")
            $writer.WriteString($attribute.Name)
            $writer.WriteEndElement(<#VULN_ATTRIBUTE#>)
            $writer.WriteStartElement("ATTRIBUTE_DATA")
            $writer.WriteString($attribute.Value)
            $writer.WriteEndElement(<#ATTRIBUTE_DATA#>)
            $writer.WriteEndElement(<#STIG_DATA#>)
        }

        $statusMap = @{
            NotReviewed   = 'Not_Reviewed'
            Open          = 'Open'
            NotAFinding   = 'NotAFinding'
            NotApplicable = 'Not_Applicable'
        }

        $manualCheck = $manualCheckData | Where-Object -FilterScript {$_.VulID -eq $VID}

        if ($PSCmdlet.ParameterSetName -eq 'nomof')
        {
            $status         = $statusMap["$($manualCheck.Status)"]
            $findingDetails = $manualCheck.Details
            $comments       = $manualCheck.Comments
        }
        else
        {
            if ($PSCmdlet.ParameterSetName -eq 'result')
            {
                $manualCheck = $manualCheckData | Where-Object -FilterScript {$_.VulID -eq $VID}

                if ($manualCheck)
                {
                    $status = $statusMap["$($manualCheck.Status)"]
                    $findingDetails = $manualCheck.Details
                    $comments = $manualCheck.Comments
                }
                else
                {
                    $setting = Get-SettingsFromResult -DscResult $dscResult -Id $vid

                    if ($setting)
                    {
                        if ($setting.InDesiredState -eq $true)
                        {
                            $status = $statusMap['NotAFinding']
                            $comments = "Addressed by PowerStig MOF via $setting"
                            $findingDetails = Get-FindingDetails -Setting $setting
                        }
                        elseif ($setting.InDesiredState -eq $false)
                        {
                            $status = $statusMap['Open']
                            $comments = "Configuration attempted by PowerStig MOF via $setting, but not currently set."
                            $findingDetails = Get-FindingDetails -Setting $setting
                        }
                        else
                        {
                            $status = $statusMap['Open']
                        }
                    }
                    else
                    {
                        $status = $statusMap['NotReviewed']
                    }
                }
            }
            else
            {

                if ($PSCmdlet.ParameterSetName -eq 'mof')
                {
                    $setting = Get-SettingsFromMof -ReferenceConfiguration $referenceConfiguration -Id $vid
                }

                $manualCheck = $manualCheckData | Where-Object {$_.VulID -eq $VID}

                if ($setting)
                {
                    $status = $statusMap['NotAFinding']
                    $comments = "To be addressed by PowerStig MOF via $setting"
                    $findingDetails = Get-FindingDetails -Setting $setting

                }
                elseif ($manualCheck)
                {
                    $status = $statusMap["$($manualCheck.Status)"]
                    $findingDetails = $manualCheck.Details
                    $comments = $manualCheck.Comments
                }
                else
                {
                    $status = $statusMap['NotReviewed']
                }
            }

            # Test to see if this rule is managed as a duplicate
            try {$convertedRule = $processed.SelectSingleNode("//Rule[@id='$vid']")}
            catch { }

            if ($convertedRule.DuplicateOf)
            {
                # How is the duplicate rule handled? If it is handled, then this duplicate is also covered
                if ($PSCmdlet.ParameterSetName -eq 'mof')
                {
                    $originalSetting = Get-SettingsFromMof -ReferenceConfiguration $referenceConfiguration -Id $convertedRule.DuplicateOf

                    if ($originalSetting)
                    {
                        $status = $statusMap['NotAFinding']
                        $findingDetails = 'See ' + $convertedRule.DuplicateOf + ' for Finding Details.'
                        $comments = 'Managed via PowerStigDsc - this rule is a duplicate of ' + $convertedRule.DuplicateOf
                    }
                }
                elseif ($PSCmdlet.ParameterSetName -eq 'result')
                {
                    $originalSetting = Get-SettingsFromResult -DscResult $dscResult -id $convertedRule.DuplicateOf

                    if ($originalSetting.InDesiredState -eq 'True')
                    {
                        $status = $statusMap['NotAFinding']
                        $findingDetails = 'See ' + $convertedRule.DuplicateOf + ' for Finding Details.'
                        $comments = 'Managed via PowerStigDsc - this rule is a duplicate of ' + $convertedRule.DuplicateOf
                    }
                    else
                    {
                        $status = $statusMap['Open']
                        $findingDetails = 'See ' + $convertedRule.DuplicateOf + ' for Finding Details.'
                        $comments = 'Managed via PowerStigDsc - this rule is a duplicate of ' + $convertedRule.DuplicateOf
                    }
                }
            }
        }

        if ($null -eq $status) 
        {
            $status   = 'Not_Reviewed'
            $Comments = "Error gathering comments"
        } 

        $writer.WriteStartElement("STATUS")
        $writer.WriteString($status)
        $writer.WriteEndElement(<#STATUS#>)
        $writer.WriteStartElement("FINDING_DETAILS")
        $writer.WriteString($findingDetails)
        $writer.WriteEndElement(<#FINDING_DETAILS#>)
        $writer.WriteStartElement("COMMENTS")
        $writer.WriteString($comments)
        $writer.WriteEndElement(<#COMMENTS#>)
        $writer.WriteStartElement("SEVERITY_OVERRIDE")
        $writer.WriteString('')
        $writer.WriteEndElement(<#SEVERITY_OVERRIDE#>)
        $writer.WriteStartElement("SEVERITY_JUSTIFICATION")
        $writer.WriteString('')
        $writer.WriteEndElement(<#SEVERITY_JUSTIFICATION#>)
        $writer.WriteEndElement(<#VULN#>)
    }

    #endregion STIGS/iSTIG/VULN[]

    $writer.WriteEndElement(<#iSTIG#>)
    $writer.WriteEndElement(<#STIGS#>)
    $writer.WriteEndElement(<#CHECKLIST#>)
    $writer.Flush()
    $writer.Close()
}

function Get-VulnerabilityList
{
    <#
    .SYNOPSIS
        Gets the vulnerability details from the rule description
    #>

    [CmdletBinding()]
    [OutputType([xml])]
    param
    (
        [Parameter()]
        [psobject]
        $XccdfBenchmark
    )

    [System.Collections.ArrayList] $vulnerabilityList = @()

    foreach ($vulnerability in $XccdfBenchmark.Group)
    {
        [xml]$vulnerabiltyDiscussionElement = "<discussionroot>$($vulnerability.Rule.description)</discussionroot>"

        [void] $vulnerabilityList.Add(
            @(
                [PSCustomObject]@{Name = 'Vuln_Num'; Value = $vulnerability.id},
                [PSCustomObject]@{Name = 'Severity'; Value = $vulnerability.Rule.severity},
                [PSCustomObject]@{Name = 'Group_Title'; Value = $vulnerability.title},
                [PSCustomObject]@{Name = 'Rule_ID'; Value = $vulnerability.Rule.id},
                [PSCustomObject]@{Name = 'Rule_Ver'; Value = $vulnerability.Rule.version},
                [PSCustomObject]@{Name = 'Rule_Title'; Value = $vulnerability.Rule.title},
                [PSCustomObject]@{Name = 'Vuln_Discuss'; Value = $vulnerabiltyDiscussionElement.discussionroot.VulnDiscussion},
                [PSCustomObject]@{Name = 'IA_Controls'; Value = $vulnerabiltyDiscussionElement.discussionroot.IAControls},
                [PSCustomObject]@{Name = 'Check_Content'; Value = $vulnerability.Rule.check.'check-content'},
                [PSCustomObject]@{Name = 'Fix_Text'; Value = $vulnerability.Rule.fixtext.InnerText},
                [PSCustomObject]@{Name = 'False_Positives'; Value = $vulnerabiltyDiscussionElement.discussionroot.FalsePositives},
                [PSCustomObject]@{Name = 'False_Negatives'; Value = $vulnerabiltyDiscussionElement.discussionroot.FalseNegatives},
                [PSCustomObject]@{Name = 'Documentable'; Value = $vulnerabiltyDiscussionElement.discussionroot.Documentable},
                [PSCustomObject]@{Name = 'Mitigations'; Value = $vulnerabiltyDiscussionElement.discussionroot.Mitigations},
                [PSCustomObject]@{Name = 'Potential_Impact'; Value = $vulnerabiltyDiscussionElement.discussionroot.PotentialImpacts},
                [PSCustomObject]@{Name = 'Third_Party_Tools'; Value = $vulnerabiltyDiscussionElement.discussionroot.ThirdPartyTools},
                [PSCustomObject]@{Name = 'Mitigation_Control'; Value = $vulnerabiltyDiscussionElement.discussionroot.MitigationControl},
                [PSCustomObject]@{Name = 'Responsibility'; Value = $vulnerabiltyDiscussionElement.discussionroot.Responsibility},
                [PSCustomObject]@{Name = 'Security_Override_Guidance'; Value = $vulnerabiltyDiscussionElement.discussionroot.SeverityOverrideGuidance},
                [PSCustomObject]@{Name = 'Check_Content_Ref'; Value = $vulnerability.Rule.check.'check-content-ref'.href},
                [PSCustomObject]@{Name = 'Weight'; Value = $vulnerability.Rule.Weight},
                [PSCustomObject]@{Name = 'Class'; Value = 'Unclass'},
                [PSCustomObject]@{Name = 'STIGRef'; Value = "$($XccdfBenchmark.title) :: $($XccdfBenchmark.'plain-text'.InnerText)"},
                [PSCustomObject]@{Name = 'TargetKey'; Value = $vulnerability.Rule.reference.identifier}

                # Some Stigs have multiple Control Correlation Identifiers (CCI)
                $(
                    # Extract only the cci entries
                    $CCIREFList = $vulnerability.Rule.ident |
                    Where-Object {$PSItem.system -eq 'http://iase.disa.mil/cci'} |
                    Select-Object 'InnerText' -ExpandProperty 'InnerText'

                    foreach ($CCIREF in $CCIREFList)
                    {
                        [PSCustomObject]@{Name = 'CCI_REF'; Value = $CCIREF}
                    }
                )
            )
        )
    }

    return $vulnerabilityList
}

function Get-MofContent
{
    <#
    .SYNOPSIS
        Converts the mof into an array of objects
    #>

    [CmdletBinding()]
    [OutputType([psobject])]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]
        $ReferenceConfiguration
    )

    if (-not $script:mofContent)
    {
        $script:mofContent = [Microsoft.PowerShell.DesiredStateConfiguration.Internal.DscClassCache]::ImportInstances($referenceConfiguration, 4)
    }

    return $script:mofContent
}

function Get-SettingsFromMof
{
    <#
    .SYNOPSIS
        Gets the stig details from the mof
    #>
    
    [CmdletBinding()]
    [OutputType([psobject])]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]
        $ReferenceConfiguration,

        [Parameter(Mandatory = $true)]
        [string]
        $Id
    )

    $mofContent = Get-MofContent -ReferenceConfiguration $referenceConfiguration
    $mofContentFound = $mofContent.Where({$PSItem.ResourceID -match $Id})
    return $mofContentFound
}

function Get-SettingsFromResult
{
    <#
    .SYNOPSIS
        Gets the stig details from the Test\Get-DscConfiguration output
    #>

    [CmdletBinding()]
    [OutputType([psobject])]
    param
    (
        [Parameter(Mandatory = $true)]
        [psobject]
        $DscResult,

        [Parameter(Mandatory = $true)]
        [string]
        $Id
    )

    $allResources = $dscResult.ResourcesNotInDesiredState + $dscResult.ResourcesInDesiredState
    return $allResources.Where({$PSItem.ResourceID -match $id})
}



function Get-FindingDetails
{
    <#
    .SYNOPSIS
        Gets the value from a STIG setting
    #>
    
    [OutputType([string])]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [AllowNull()]
        [psobject]
        $Setting
    )

    switch ($setting.ResourceID)
    {
        # Only add custom entries if specific output is more valuable than dumping all properties
        {$PSItem -match "^\[None\]"}
        {
            return "No DSC resource was leveraged for this rule (Resource=None)"
        }
        {$PSItem -match "^\[(x)?Registry\]"}
        {
            return "Registry Value = $($setting.ValueData)"
        }
        {$PSItem -match "^\[UserRightsAssignment\]"}
        {
            return "UserRightsAssignment Identity = $($setting.Identity)"
        }
        default
        {
            return Get-FindingDetailsString -Setting $setting
        }
    }
}


function Get-FindingDetailsString
{
    <#
    
    .SYNOPSIS
        Formats properties and values with standard string format.

    #>

    [OutputType([string])]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [AllowNull()]
        [psobject]
        $Setting
    )

    foreach ($property in $setting.PSobject.properties) {
        if ($property.TypeNameOfValue -Match 'String')
        {
            $returnString += $($property.Name) + ' = '
            $returnString += $($setting.PSobject.properties[$property.Name].Value) + "`n"
        }
    }
    return $returnString
}

function Get-TargetNodeFromMof
{
    [OutputType([string])]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [string]
        $MofString
    )

    $pattern = "((?<=@TargetNode=')(.*)(?='))"
    $TargetNodeSearch = $mofstring | Select-String -Pattern $pattern
    $TargetNode = $TargetNodeSearch.matches.value
    return $TargetNode
}

function Get-TargetNodeType
{
    [OutputType([string])]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [string]
        $TargetNode
    )

    switch ($TargetNode)
    {
        # Do we have a MAC address?
        {
            $_ -match '(([0-9a-f]{2}:){5}[0-9a-f]{2})'
        }
        {
            return 'MACAddress'
        }

        # Do we have an IPv6 address?
        {
            $_ -match '(([0-9a-f]{0,4}:){7}[0-9a-f]{0,4})'
        }
        {
            return 'IPv4Address'
        }

        # Do we have an IPv4 address?
        {
            $_ -match '(([0-9]{1,3}\.){3}[0-9]{1,3})'
        }
        {
            return 'IPv6Address'
        }

        # Do we have a Fully-qualified Domain Name?
        {
            $_ -match '([a-zA-Z0-9-.\+]{2,256}\.[a-z]{2,256}\b)'
        }
        {
            return 'FQDN'
        }
    }

    return ''
}

function Get-StigXccdfBenchmarkContent
{
    [CmdletBinding()]
    [OutputType([xml])]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]
        $Path
    )

    if (-not (Test-Path -Path $path))
    {
        Throw "The file $path was not found"
    }

    if ($path -like "*.zip")
    {
        [xml] $xccdfXmlContent = Get-StigContentFromZip -Path $path
    }
    else
    {
        [xml] $xccdfXmlContent = Get-Content -Path $path -Encoding UTF8
    }

    $xccdfXmlContent.Benchmark
}