Configuration PowerSTIG_FireFox
{
    param(
        [Parameter()]
        [string]
        $InstallDirectory = "$env:ProgramFiles\Mozilla Firefox",

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
            FireFox Baseline
            {
                InstallDirectory    = $InstallDirectory
            }
        }
        elseif ( $null -ne $SkipRule -and $null -eq $Exception )
        {
            FireFox Baseline
            {
                InstallDirectory    = $InstallDirectory
                Skiprule            = $SkipRule
            }
        }
        elseif ( $null -eq $SkipRule -and $null -ne $Exception )
        {
            FireFox Baseline
            {
                InstallDirectory    = $InstallDirectory
                Exception           = $Exception
            }
        }
        elseif ( $null -ne $SkipRule -and $null -ne $Exception )
        {
            FireFox Baseline
            {
                InstallDirectory    = $InstallDirectory
                Skiprule            = $SkipRule
                Exception           = $Exception
            }
        }
    }
    else
    {
        if ( $null -eq $SkipRule -and $null -eq $Exception )
        {
            FireFox Baseline
            {
                InstallDirectory    = $InstallDirectory
                OrgSettings         = $OrgSettings
            }
        }
        elseif ( $null -ne $SkipRule -and $null -eq $Exception )
        {
            FireFox Baseline
            {
                InstallDirectory    = $InstallDirectory
                OrgSettings         = $OrgSettings
                Skiprule            = $SkipRule
            }
        }
        elseif ( $null -eq $SkipRule -and $null -ne $Exception )
        {
            FireFox Baseline
            {
                InstallDirectory    = $InstallDirectory
                OrgSettings         = $OrgSettings
                Exception           = $Exception
            }
        }
        elseif ( $null -ne $SkipRule -and $null -ne $Exception )
        {
            FireFox Baseline
            {
                InstallDirectory    = $InstallDirectory
                OrgSettings         = $OrgSettings
                Skiprule            = $SkipRule
                Exception           = $Exception
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
Configuration PowerSTIG_WindowsServer
{
    param(
        [Parameter()]
        [string]
        $OsVersion,

        [Parameter()]
        [string]
        $OsRole,

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
            WindowsServer BaseLine
            {
                OsVersion   = $OSVersion
                OsRole      = $OSRole
            }
        }
        elseif ($null -ne $SkipRule -and $null -eq $Exception)
        {
            WindowsServer BaseLine
            {
                OsVersion   = $OSVersion
                OsRole      = $OSRole
                SkipRule    = $SkipRule
            }
        }
        elseif ($null -eq $skiprule -and $null -ne $Exception)
        {
            WindowsServer BaseLine
            {
                OsVersion   = $OSVersion
                OsRole      = $OSRole
                Exception   = $Exception
            }
        }
        elseif ( ($null -ne $Exception ) -and ($null -ne $SkipRule) )
        {
            WindowsServer Baseline
            {
                OsVersion   = $OSVersion
                OsRole      = $OSRole
                Exception   = $Exception
                SkipRule    = $SkipRule
            }
        }
    }
    elseif ($null-ne $orgsettings)
    {
        if ( ($null -eq $SkipRule) -and ($null -eq $Exception) )
        {
            WindowsServer BaseLine
            {
                OsVersion   = $OSVersion
                OsRole      = $OSRole
                OrgSettings = $OrgSettings
            }
        }
        elseif ($null -ne $SkipRule -and $null -eq $exception)
        {
            WindowsServer BaseLine
            {
                OsVersion   = $OSVersion
                OsRole      = $OSRole
                OrgSettings = $OrgSettings
                SkipRule    = $SkipRule
            }
        }
        elseif ( $null -eq $skiprule -and $null -ne $Exception ) {
            WindowsServer BaseLine
            {
                OsVersion   = $OSVersion
                OsRole      = $OSRole
                OrgSettings = $OrgSettings
                Exception   = $Exception
            }
        }
        elseif ( ($null -ne $Exception ) -and ($null -ne $SkipRule) )
        {
            WindowsServer Baseline
            {
                OsVersion   = $OSVersion
                OsRole      = $OSRole
                OrgSettings = $OrgSettings
                Exception   = $Exception
                SkipRule    = $SkipRule
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
Configuration PowerSTIG_WebServer
{

    param(
        [Parameter(Mandatory = $true)]
        [version]
        $IISVersion,

        [Parameter(Mandatory = $true)]
        [string]
        $LogPath,

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
            IISServer Baseline
            {
                IISVersion      = $IISVersion
                LogPath         = $LogPath
            }
        }
        elseif ( $null -ne $SkipRule -and $null -eq $Exception )
        {
            IISServer Baseline
            {
                IISVersion      = $IisVersion
                LogPath         = $LogPath
                Skiprule        = $SkipRule
            }
        }
        elseif ( $null -eq $SkipRule -and $null -ne $Exception )
        {
            IISServer Baseline
            {
                IISVersion      = $IisVersion
                LogPath         = $LogPath
                Exception       = $Exception
            }
        }
        elseif ( $null -ne $SkipRule -and $null -ne $Exception )
        {
            IISServer Baseline
            {
                IISVersion      = $IisVersion
                LogPath         = $LogPath
                Skiprule        = $SkipRule
                Exception       = $Exception
            }
        }
    }
    else
    {
        if ( $null -eq $SkipRule -and $null -eq $Exception )
        {
            IISServer Baseline
            {
                IISVersion      = $IisVersion
                LogPath         = $LogPath
                OrgSettings     = $OrgSettings
            }
        }
        elseif ( $null -ne $SkipRule -and $null -eq $Exception )
        {
            IISServer Baseline
            {
                IISVersion      = $IisVersion
                LogPath         = $LogPath
                OrgSettings     = $OrgSettings
                Skiprule        = $SkipRule
            }
        }
        elseif ( $null -eq $SkipRule -and $null -ne $Exception )
        {
            IISServer Baseline
            {
                IISVersion      = $IisVersion
                LogPath         = $LogPath
                OrgSettings     = $OrgSettings
                Exception       = $Exception
            }
        }
        elseif ( $null -ne $SkipRule -and $null -ne $Exception )
        {
            IISServer Baseline
            {
                IISVersion      = $IisVersion
                LogPath         = $LogPath
                OrgSettings     = $OrgSettings
                Skiprule        = $SkipRule
                Exception       = $Exception
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
Configuration PowerSTIG_WebSite
{

    param(
        [Parameter(Mandatory = $true)]
        [version]
        $IisVersion,

        [Parameter()]
        [string[]]
        $WebsiteName,

        [Parameter()]
        [string[]]
        $WebAppPool,

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

    Import-DscResource -Modulename 'PowerStig'

    if ( $null -eq $OrgSettings -or "" -eq $OrgSettings )
    {
        if ( $null -eq $SkipRule -and $null -eq $Exception )
        {
            IISSite Baseline
            {
                IISVersion      = $IISVersion
                WebsiteName     = $WebsiteName
                WebAppPool      = $WebAppPool
            }
        }
        elseif ( $null -ne $SkipRule -and $null -eq $Exception )
        {
            IISSite Baseline
            {
                IISVersion      = $IisVersion
                WebsiteName     = $WebsiteName
                WebAppPool      = $WebAppPool
                Skiprule        = $SkipRule
            }
        }
        elseif ( $null -eq $SkipRule -and $null -ne $Exception )
        {
            IISSite Baseline
            {
                IISVersion      = $IisVersion
                WebsiteName     = $WebsiteName
                WebAppPool      = $WebAppPool
                Exception       = $Exception
            }
        }
        elseif ( $null -ne $SkipRule -and $null -ne $Exception )
        {
            IISSite Baseline
            {
                IISVersion      = $IisVersion
                WebsiteName     = $WebsiteName
                WebAppPool      = $WebAppPool
                Skiprule        = $SkipRule
                Exception       = $Exception
            }
        }
    }
    else
    {
        if ( $null -eq $SkipRule -and $null -eq $Exception )
        {
            IISSite Baseline
            {
                IISVersion      = $IisVersion
                WebsiteName     = $WebsiteName
                WebAppPool      = $WebAppPool
                OrgSettings     = $OrgSettings
            }
        }
        elseif ( $null -ne $SkipRule -and $null -eq $Exception )
        {
            IISSite Baseline
            {
                IISVersion      = $IisVersion
                WebsiteName     = $WebsiteName
                WebAppPool      = $WebAppPool
                OrgSettings     = $OrgSettings
                Skiprule        = $SkipRule
            }
        }
        elseif ( $null -eq $SkipRule -and $null -ne $Exception )
        {
            IISSite Baseline
            {
                IISVersion      = $IisVersion
                WebsiteName     = $WebsiteName
                WebAppPool      = $WebAppPool
                OrgSettings     = $OrgSettings
                Exception       = $Exception
            }
        }
        elseif ( $null -ne $SkipRule -and $null -ne $Exception )
        {
            IISSite Baseline
            {
                IISVersion      = $IisVersion
                WebsiteName     = $WebsiteName
                WebAppPool      = $WebAppPool
                OrgSettings     = $OrgSettings
                Skiprule        = $SkipRule
                Exception       = $Exception
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
Configuration MainConfig
{
	Node $AllNodes.Where{$_.NodeName -eq "VM-WS-001"}.NodeName
	{
		PowerSTIG_Firefox PowerSTIG_Firefox
		{
			InstallDirectory = $node.appliedconfigurations.PowerSTIG_Firefox["InstallDirectory"]
			OrgSettings = $node.appliedconfigurations.PowerSTIG_Firefox["OrgSettings"]
		}

		PowerSTIG_DotNetFrameWork PowerSTIG_DotNetFrameWork
		{
			FrameworkVersion = $node.appliedconfigurations.PowerSTIG_DotNetFrameWork["FrameworkVersion"]
			OrgSettings = $node.appliedconfigurations.PowerSTIG_DotNetFrameWork["OrgSettings"]
		}

		PowerSTIG_InternetExplorer PowerSTIG_InternetExplorer
		{
			BrowserVersion = $node.appliedconfigurations.PowerSTIG_InternetExplorer["BrowserVersion"]
			OrgSettings = $node.appliedconfigurations.PowerSTIG_InternetExplorer["OrgSettings"]
			SkipRule = $node.appliedconfigurations.PowerSTIG_InternetExplorer["SkipRule"]
		}

		PowerSTIG_WindowsServer PowerSTIG_WindowsServer
		{
			OsVersion = $node.appliedconfigurations.PowerSTIG_WindowsServer["OsVersion"]
			OsRole = $node.appliedconfigurations.PowerSTIG_WindowsServer["OsRole"]
			OrgSettings = $node.appliedconfigurations.PowerSTIG_WindowsServer["OrgSettings"]
		}

		PowerSTIG_WebServer PowerSTIG_WebServer
		{
			IISVersion = $node.appliedconfigurations.PowerSTIG_WebServer["IISVersion"]
			LogPath = $node.appliedconfigurations.PowerSTIG_WebServer["LogPath"]
			OrgSettings = $node.appliedconfigurations.PowerSTIG_WebServer["OrgSettings"]
			SkipRule = $node.appliedconfigurations.PowerSTIG_WebServer["SkipRule"]
		}

		PowerSTIG_WebSite PowerSTIG_WebSite
		{
			IisVersion = $node.appliedconfigurations.PowerSTIG_WebSite["IisVersion"]
			WebsiteName = $node.appliedconfigurations.PowerSTIG_WebSite["WebsiteName"]
			WebAppPool = $node.appliedconfigurations.PowerSTIG_WebSite["WebAppPool"]
			OrgSettings = $node.appliedconfigurations.PowerSTIG_WebSite["OrgSettings"]
		}
	}
}

[DscLocalConfigurationManager()]
Configuration LocalConfigurationManager
{
	Node $AllNodes.Where{$_.NodeName -eq "VM-WS-001"}.NodeName
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
