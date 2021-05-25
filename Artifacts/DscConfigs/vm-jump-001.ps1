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
Configuration PowerSTIG_WindowsDefender
{
    param(
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

    Import-DSCResource -Modulename 'PowerSTIG'

    if ( $null -eq $OrgSettings -or "" -eq $OrgSettings )
    {
        if ( ($null -eq $SkipRule) -and ($null -eq $Exception) )
        {
            WindowsDefender BaseLine
            {
            }
        }
        elseif ($null -ne $SkipRule -and $null -eq $Exception)
        {
            WindowsDefender BaseLine
            {
                SkipRule    = $SkipRule
            }
        }
        elseif ($null -eq $skiprule -and $null -ne $Exception) {
            WindowsDefender BaseLine
            {
                Exception   = $Exception
            }
        }
        elseif ( ($null -ne $Exception ) -and ($null -ne $SkipRule) )
        {
            WindowsDefender Baseline
            {
                Exception   = $Exception
                SkipRule    = $SkipRule
            }
        }
    }
    else
    {
        if ( ($null -eq $SkipRule) -and ($null -eq $Exception) )
        {
            WindowsDefender BaseLine
            {
                OrgSettings = $OrgSettings
            }
        }
        elseif ($null -ne $SkipRule -and $null -eq $exception)
        {
            WindowsDefender BaseLine
            {
                OrgSettings = $OrgSettings
                SkipRule    = $SkipRule
            }
        }
        elseif ( $null -eq $skiprule -and $null -ne $Exception ) {
            WindowsDefender BaseLine
            {
                OrgSettings = $OrgSettings
                Exception   = $Exception
            }
        }
        elseif ( ($null -ne $Exception ) -and ($null -ne $SkipRule) )
        {
            WindowsDefender Baseline
            {
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
Configuration PowerSTIG_WindowsFirewall
{
    param(
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
            WindowsFirewall BaseLine
            {
            }
        }
        elseif ($null -ne $SkipRule -and $null -eq $Exception)
        {
            WindowsFirewall BaseLine
            {
                SkipRule    = $SkipRule
            }
        }
        elseif ($null -eq $skiprule -and $null -ne $Exception) {
            WindowsFirewall BaseLine
            {
                Exception   = $Exception
            }
        }
        elseif ( ($null -ne $Exception ) -and ($null -ne $SkipRule) )
        {
            WindowsFirewall Baseline
            {
                Exception   = $Exception
                SkipRule    = $SkipRule
            }
        }
    }
    else
    {
        if ( ($null -eq $SkipRule) -and ($null -eq $Exception) )
        {
            WindowsFirewall BaseLine
            {
                OrgSettings = $OrgSettings
            }
        }
        elseif ($null -ne $SkipRule -and $null -eq $exception)
        {
            WindowsFirewall BaseLine
            {
                OrgSettings = $OrgSettings
                SkipRule    = $SkipRule
            }
        }
        elseif ( $null -eq $skiprule -and $null -ne $Exception ) {
            WindowsFirewall BaseLine
            {
                OrgSettings = $OrgSettings
                Exception   = $Exception
            }
        }
        elseif ( ($null -ne $Exception ) -and ($null -ne $SkipRule) )
        {
            WindowsFirewall Baseline
            {
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
Configuration PowerSTIG_Edge
{
    param(

        [Parameter()]
        [version]
        $StigVersion,

        [Parameter()]
        [hashtable]
        $Exception,

        [Parameter()]
        [string]
        $OrgSettings = "C:\Users\jadean-sa\Desktop\SCAR\Resources\Stig Data\Organizational Settings\Microsoft-Edge-1.1.org.default.xml",

        [Parameter()]
        [string[]]
        $SkipRule
    )

    Import-DscResource -ModuleName 'PowerStig'

    if ( $null -eq $OrgSettings -or "" -eq $OrgSettings )
    {
        if ( $null -eq $SkipRule -and $null -eq $Exception )
        {
            Edge Baseline
            {

            }
        }
        elseif ( $null -ne $SkipRule -and $null -eq $Exception )
        {
            Edge Baseline
            {

                Skiprule            = $SkipRule
            }
        }
        elseif ( $null -eq $SkipRule -and $null -ne $Exception )
        {
            Edge Baseline
            {

                Exception           = $Exception
            }
        }
        elseif ( $null -ne $SkipRule -and $null -ne $Exception )
        {
            Edge Baseline
            {

                Skiprule            = $SkipRule
                Exception           = $Exception
            }
        }
    }
    else
    {
        if ( $null -eq $SkipRule -and $null -eq $Exception )
        {
            Edge Baseline
            {

                OrgSettings         = $OrgSettings
            }
        }
        elseif ( $null -ne $SkipRule -and $null -eq $Exception )
        {
            Edge Baseline
            {

                OrgSettings         = $OrgSettings
                Skiprule            = $SkipRule
            }
        }
        elseif ( $null -eq $SkipRule -and $null -ne $Exception )
        {
            Edge Baseline
            {

                OrgSettings         = $OrgSettings
                Exception           = $Exception
            }
        }
        elseif ( $null -ne $SkipRule -and $null -ne $Exception )
        {
            Edge Baseline
            {

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
Configuration MainConfig
{
	Node $AllNodes.Where{$_.NodeName -eq "vm-jump-001"}.NodeName
	{
		PowerSTIG_WebSite PowerSTIG_WebSite
		{
			IisVersion = $node.appliedconfigurations.PowerSTIG_WebSite["IisVersion"]
			WebsiteName = $node.appliedconfigurations.PowerSTIG_WebSite["WebsiteName"]
			WebAppPool = $node.appliedconfigurations.PowerSTIG_WebSite["WebAppPool"]
			OrgSettings = $node.appliedconfigurations.PowerSTIG_WebSite["OrgSettings"]
		}

		PowerSTIG_WindowsServer PowerSTIG_WindowsServer
		{
			OsVersion = $node.appliedconfigurations.PowerSTIG_WindowsServer["OsVersion"]
			OsRole = $node.appliedconfigurations.PowerSTIG_WindowsServer["OsRole"]
			OrgSettings = $node.appliedconfigurations.PowerSTIG_WindowsServer["OrgSettings"]
		}

		PowerSTIG_WindowsDefender PowerSTIG_WindowsDefender
		{
			OrgSettings = $node.appliedconfigurations.PowerSTIG_WindowsDefender["OrgSettings"]
		}

		PowerSTIG_DotNetFrameWork PowerSTIG_DotNetFrameWork
		{
			FrameworkVersion = $node.appliedconfigurations.PowerSTIG_DotNetFrameWork["FrameworkVersion"]
			OrgSettings = $node.appliedconfigurations.PowerSTIG_DotNetFrameWork["OrgSettings"]
		}

		PowerSTIG_WindowsFirewall PowerSTIG_WindowsFirewall
		{
			OrgSettings = $node.appliedconfigurations.PowerSTIG_WindowsFirewall["OrgSettings"]
		}

		PowerSTIG_WebServer PowerSTIG_WebServer
		{
			IISVersion = $node.appliedconfigurations.PowerSTIG_WebServer["IISVersion"]
			LogPath = $node.appliedconfigurations.PowerSTIG_WebServer["LogPath"]
			OrgSettings = $node.appliedconfigurations.PowerSTIG_WebServer["OrgSettings"]
			SkipRule = $node.appliedconfigurations.PowerSTIG_WebServer["SkipRule"]
		}

		PowerSTIG_InternetExplorer PowerSTIG_InternetExplorer
		{
			BrowserVersion = $node.appliedconfigurations.PowerSTIG_InternetExplorer["BrowserVersion"]
			OrgSettings = $node.appliedconfigurations.PowerSTIG_InternetExplorer["OrgSettings"]
			SkipRule = $node.appliedconfigurations.PowerSTIG_InternetExplorer["SkipRule"]
		}

		PowerSTIG_Edge PowerSTIG_Edge
		{
			OrgSettings = $node.appliedconfigurations.PowerSTIG_Edge["OrgSettings"]
		}
	}
}
[DscLocalConfigurationManager()]
Configuration LocalConfigurationManager
{
	Node $AllNodes.Where{$_.NodeName -eq "vm-jump-001"}.NodeName
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