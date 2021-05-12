Configuration PowerSTIG_InternetExplorer
{
    param(
        [Parameter(Mandatory = $true)]
        [int]
        $BrowserVersion,

        [Parameter()]
        [version]
        $StigVersion,

        [Parameter()]
        [hashtable]
        $Exception,

        [Parameter()]
        [string]
        $OrgSettings,

        [Parameter()]
        [string[]]
        $SkipRule
    )

    Import-DscResource -ModuleName 'PowerStig'

    if ( $null -eq $OrgSettings -or "" -eq $OrgSettings )
    {
        if ( $null -eq $SkipRule -and $null -eq $Exception )
        {
            InternetExplorer Baseline
            {
                BrowserVersion  = $BrowserVersion
            }
        }
        elseif ( $null -ne $SkipRule -and $null -eq $Exception )
        {
            InternetExplorer Baseline
            {
                BrowserVersion  = $BrowserVersion
                Skiprule        = $SkipRule
            }
        }
        elseif ( $null -eq $SkipRule -and $null -ne $Exception )
        {
            InternetExplorer Baseline
            {
                BrowserVersion  = $BrowserVersion
                Exception       = $Exception
            }
        }
        elseif ( $null -ne $SkipRule -and $null -ne $Exception )
        {
            InternetExplorer Baseline
            {
                BrowserVersion  = $BrowserVersion
                Skiprule        = $SkipRule
                Exception       = $Exception
            }
        }
    }
    else
    {
        if ( $null -eq $SkipRule -and $null -eq $Exception )
        {
            InternetExplorer Baseline
            {
                BrowserVersion  = $BrowserVersion
                OrgSettings     = $OrgSettings
            }
        }
        elseif ( $null -ne $SkipRule -and $null -eq $Exception )
        {
            InternetExplorer Baseline
            {
                BrowserVersion  = $BrowserVersion
                OrgSettings     = $OrgSettings
                Skiprule        = $SkipRule
            }
        }
        elseif ( $null -eq $SkipRule -and $null -ne $Exception )
        {
            InternetExplorer Baseline
            {
                BrowserVersion  = $BrowserVersion
                OrgSettings     = $OrgSettings
                Exception       = $Exception
            }
        }
        elseif ( $null -ne $SkipRule -and $null -ne $Exception )
        {
            InternetExplorer Baseline
            {
                BrowserVersion  = $BrowserVersion
                OrgSettings     = $OrgSettings
                Skiprule        = $SkipRule
                Exception       = $Exception
            }
        }
    }

    foreach ( $rule in $SkipRule.Keys )
    {
        Registry Exception_Rule
        {
            Ensure = "Present"
            Key = "HKEY_LOCAL_MACHINE\SOFTWARE\STIGExceptions\"
            ValueName = $rule
            ValueData = $(Get-Date -format "MMddyyyy")
            ValueType = "String"
            Force = $true
        }
    }
}
Configuration PowerSTIG_DotNetFramework
{
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $FrameworkVersion,

        [Parameter()]
        [version]
        $StigVersion,

        [Parameter()]
        [hashtable]
        $Exception,

        [Parameter()]
        [string]
        $OrgSettings,

        [Parameter()]
        [string[]]
        $SkipRule
    )

    Import-DscResource -ModuleName 'PowerStig'

    if ( $null -eq $OrgSettings -or "" -eq $OrgSettings )
    {
        if ( $null -eq $SkipRule -and $null -eq $Exception )
        {
            DotNetFramework Baseline
            {
                FrameworkVersion    = $FrameworkVersion
            }
        }
        elseif ( $null -ne $SkipRule -and $null -eq $Exception )
        {
            DotNetFramework Baseline
            {
                FrameworkVersion    = $FrameworkVersion
                Skiprule            = $SkipRule
            }
        }
        elseif ( $null -eq $SkipRule -and $null -ne $Exception )
        {
            DotNetFramework Baseline
            {
                FrameworkVersion    = $FrameworkVersion
                Exception           = $Exception
            }
        }
        elseif ( $null -ne $SkipRule -and $null -ne $Exception )
        {
            DotNetFramework Baseline
            {
                FrameworkVersion    = $FrameworkVersion
                Skiprule            = $SkipRule
                Exception           = $Exception
            }
        }
    }
    else
    {
        if ( $null -eq $SkipRule -and $null -eq $Exception )
        {
            DotNetFramework Baseline
            {
                FrameworkVersion    = $FrameworkVersion
                OrgSettings         = $OrgSettings
            }
        }
        elseif ( $null -ne $SkipRule -and $null -eq $Exception )
        {
            DotNetFramework Baseline
            {
                FrameworkVersion    = $FrameworkVersion
                OrgSettings         = $OrgSettings
                Skiprule            = $SkipRule
            }
        }
        elseif ( $null -eq $SkipRule -and $null -ne $Exception )
        {
            DotNetFramework Baseline
            {
                FrameworkVersion    = $FrameworkVersion
                OrgSettings         = $OrgSettings
                Exception           = $Exception
            }
        }
        elseif ( $null -ne $SkipRule -and $null -ne $Exception )
        {
            DotNetFramework Baseline
            {
                FrameworkVersion    = $FrameworkVersion
                OrgSettings         = $OrgSettings
                Skiprule            = $SkipRule
                Exception           = $Exception
            }
        }
    }

    foreach($rule in $SkipRule.Keys)
    {
        Registry Exception_Rule
        {
            Ensure      = "Present"
            Key         = "HKEY_LOCAL_MACHINE\SOFTWARE\STIGExceptions\"
            ValueName   = $rule
            ValueData   = $(Get-Date -format "MMddyyyy")
            ValueType   = "String"
            Force       = $true
        }
    }
}
Configuration PowerSTIG_WindowsClient
{
    param(
        [Parameter()]
        [string]
        $OsVersion,

        [Parameter()]
        [version]
        $StigVersion,

        [Parameter()]
        [hashtable]
        $Exception,

        [Parameter()]
        [string]
        $OrgSettings,

        [Parameter()]
        [string[]]
        $SkipRule
    )

    Import-DSCResource -Module PowerSTIG

    if ( $null -eq $OrgSettings -or "" -eq $OrgSettings )
    {
        if ( ($null -eq $SkipRule) -and ($null -eq $Exception) )
        {
            WindowsClient BaseLine
            {
                OsVersion = [String]$OSVersion
                
                DomainName = $DomainName
                Forestname = $Forestname
            }
        }
        elseif ($null -ne $SkipRule -and $null -eq $Exception)
        {
            WindowsClient BaseLine
            {
                OsVersion = [String]$OSVersion
                
                DomainName = $DomainName
                ForestName = $ForestName
                SkipRule = $SkipRule
            }
        }
        elseif ($null -eq $skiprule -and $null -ne $Exception) {
            WindowsClient BaseLine
            {
                OsVersion = [String]$OSVersion
                
                DomainName = $DomainName
                ForestName = $ForestName
                Exception = $Exception
            }
        }
        elseif ( ($null -ne $Exception ) -and ($null -ne $SkipRule) )
        {
            WindowsClient Baseline
            {
                OsVersion   = [String]$OSVersion
                
                DomainName  = $DomainName
                ForestName  = $ForestName
                Exception   = $Exception
                SkipRule    = $SkipRule
            }
        }
    }
    else
    {
        if ( ($null -eq $SkipRule) -and ($null -eq $Exception) )
        {
            WindowsClient BaseLine
            {
                OsVersion = [String]$OSVersion
                
                DomainName = $DomainName
                Forestname = $Forestname
                OrgSettings = $OrgSettings
            }
        }

        elseif ($null -ne $SkipRule -and $null -eq $exception)
        {
            WindowsClient BaseLine
            {
                OsVersion = [String]$OSVersion
                
                DomainName = $DomainName
                ForestName = $ForestName
                OrgSettings = $OrgSettings
                SkipRule = $SkipRule
            }
        }
        elseif ( $null -eq $skiprule -and $null -ne $Exception ) {
            WindowsClient BaseLine
            {
                OsVersion = [String]$OSVersion
                
                DomainName = $DomainName
                ForestName = $ForestName
                OrgSettings = $OrgSettings
                Exception = $Exception
            }
        }
        elseif ( ($null -ne $Exception ) -and ($null -ne $SkipRule) )
        {
            WindowsClient Baseline
            {
                OsVersion = [String]$OSVersion
                
                DomainName = $DomainName
                ForestName = $ForestName
                OrgSettings = $OrgSettings
                Exception = $Exception
                SkipRule = $SkipRule
            }
        }
    }

    foreach($rule in $SkipRule.Keys)
    {
        Registry Exception_Rule
        {
            Ensure = "Present"
            Key = "HKEY_LOCAL_MACHINE\SOFTWARE\STIGExceptions\"
            ValueName = $rule
            ValueData = $(Get-Date -format "MMddyyyy")
            ValueType = "String"
            Force = $true
        }
    }
}
Configuration MainConfig
{
	Node $AllNodes.Where{$_.NodeName -eq "WinClient-1809"}.NodeName
	{
		PowerSTIG_InternetExplorer PowerSTIG_InternetExplorer
		{
			BrowserVersion = $node.appliedconfigurations.PowerSTIG_InternetExplorer["BrowserVersion"]
			OrgSettings = $node.appliedconfigurations.PowerSTIG_InternetExplorer["OrgSettings"]
			SkipRule = $node.appliedconfigurations.PowerSTIG_InternetExplorer["SkipRule"]
		}

		PowerSTIG_DotNetFrameWork PowerSTIG_DotNetFrameWork
		{
			FrameworkVersion = $node.appliedconfigurations.PowerSTIG_DotNetFrameWork["FrameworkVersion"]
			OrgSettings = $node.appliedconfigurations.PowerSTIG_DotNetFrameWork["OrgSettings"]
		}

		PowerSTIG_WindowsClient PowerSTIG_WindowsClient
		{
			OsVersion = $node.appliedconfigurations.PowerSTIG_WindowsClient["OsVersion"]
			OrgSettings = $node.appliedconfigurations.PowerSTIG_WindowsClient["OrgSettings"]
		}
	}
}

[DscLocalConfigurationManager()]
Configuration LocalConfigurationManager
{
	Node $AllNodes.Where{$_.NodeName -eq "WinClient-1809"}.NodeName
	{
		Settings {
			refreshFrequencyMins = $Node.LocalconfigurationManager.refreshFrequencyMins
			configurationModeFrequencyMins = $Node.LocalconfigurationManager.configurationModeFrequencyMins
			configurationMode = $Node.LocalconfigurationManager.configurationMode
			statusRetentionTimeInDays = $Node.LocalconfigurationManager.statusRetentionTimeInDays
			refreshMode = $Node.LocalconfigurationManager.refreshMode
			allowModuleOverwrite = $Node.LocalconfigurationManager.allowModuleOverwrite
			maximumDownloadSizeMB = $Node.LocalconfigurationManager.maximumDownloadSizeMB
			rebootNodeIfNeeded = $Node.LocalconfigurationManager.rebootNodeIfNeeded
		}
	}
}
