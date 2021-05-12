@{
	NodeName = "vm-jump-001"

	LocalConfigurationManager =
	@{
		refreshFrequencyMins			= "30"
		refreshMode						= "PUSH"
		allowModuleOverwrite			= $True
		configurationMode				= "ApplyAndAutoCorrect"
		rebootNodeIfNeeded				= $False
		maximumDownloadSizeMB			= "500"
		configurationModeFrequencyMins	= "15"
		statusRetentionTimeInDays		= "10"
	}

	AppliedConfigurations  =
	@{

		PowerSTIG_InternetExplorer =
		@{
			BrowserVersion 		= "11"
			OrgSettings			= "C:\Users\jadean-sa\Desktop\SCAR\Resources\Stig Data\Organizational Settings\InternetExplorer-11-1.19.org.default.xml"
			xccdfPath			= "C:\Users\jadean-sa\Desktop\SCAR\Resources\Stig Data\XCCDFs\InternetExplorer\U_MS_IE11_STIG_V1R19_Manual-xccdf.xml"
			SkipRule 			= "V-46477"
		}

		PowerSTIG_DotNetFrameWork =
		@{
			FrameWorkVersion 	= "4"
			xccdfPath			= "C:\Users\jadean-sa\Desktop\SCAR\Resources\Stig Data\XCCDFs\DotNet\U_MS_DotNet_Framework_4-0_STIG_V2R1_Manual-xccdf.xml"
			OrgSettings			= "C:\Users\jadean-sa\Desktop\SCAR\Resources\Stig Data\Organizational Settings\DotNetFramework-4-1.9.org.default.xml"
			ManualChecks 		= "C:\Users\jadean-sa\Desktop\SCAR\Resources\Stig Data\Manual Checks\DotnetFramework\DotNetFramework-4-V1R9-ManualChecks.psd1"
		}

		PowerSTIG_Edge =
		@{
			OrgSettings          = "C:\Users\jadean-sa\Desktop\SCAR\Resources\Stig Data\Organizational Settings\Microsoft-Edge-1.1.org.default.xml"
			ManualChecks         = "C:\Users\jadean-sa\Desktop\SCAR\Resources\Stig Data\Manual Checks\Edge\Edge-1R1-ManualChecks.psd1"
			xccdfPath            = "C:\Users\jadean-sa\Desktop\SCAR\Resources\Stig Data\XCCDFs\Edge\U_MS_Edge_V1R1_STIG_Manual-xccdf.xml"
		}

		PowerSTIG_WebServer =
		@{
			SkipRule         = "V-214429"
			IISVersion       = "10.0"
			LogPath          = "C:\InetPub\Logs"
			XccdfPath        = "C:\Users\jadean-sa\Desktop\SCAR\Resources\Stig Data\XCCDFs\Web Server\U_MS_IIS_10-0_Server_STIG_V2R1_Manual-xccdf.xml"
			OrgSettings      = "C:\Users\jadean-sa\Desktop\SCAR\Resources\Stig Data\Organizational Settings\IISServer-10.0-2.1.org.default.xml"
			ManualChecks     = "C:\Users\jadean-sa\Desktop\SCAR\Resources\Stig Data\Manual Checks\WebServer\WebServer-10.0-2R1-ManualChecks.psd1"
		}

		PowerSTIG_WebSite =
		@{
			IISVersion       = "10.0"
			WebsiteName      = "Default Web Site"
			WebAppPool       = "DefaultAppPool"
			XccdfPath        = "C:\Users\jadean-sa\Desktop\SCAR\Resources\Stig Data\XCCDFs\Web Server\U_MS_IIS_10-0_Site_STIG_V2R1_Manual-xccdf.xml"
			OrgSettings      = "C:\Users\jadean-sa\Desktop\SCAR\Resources\Stig Data\Organizational Settings\IISSite-10.0-2.1.org.default.xml"
			ManualChecks     = "C:\Users\jadean-sa\Desktop\SCAR\Resources\Stig Data\Manual Checks\WebSite\WebSite-10.0-2R1-ManualChecks.psd1"
		}

		PowerSTIG_WindowsDefender =
		@{
			OrgSettings          = "C:\Users\jadean-sa\Desktop\SCAR\Resources\Stig Data\Organizational Settings\WindowsDefender-All-2.1.org.default.xml"
			ManualChecks         = "C:\Users\jadean-sa\Desktop\SCAR\Resources\Stig Data\Manual Checks\WindowsDefender\WindowsDefender-1R4-ManualChecks.psd1"
			xccdfPath            = "C:\Users\jadean-sa\Desktop\SCAR\Resources\Stig Data\XCCDFs\Windows.Defender\U_MS_Windows_Defender_Antivirus_STIG_V2R1_Manual-xccdf.xml"
		}

		PowerSTIG_WindowsServer =
		@{
			OSRole               = "MS"
			OsVersion            = "2016"
			OrgSettings          = "C:\Users\jadean-sa\Desktop\SCAR\Resources\Stig Data\Organizational Settings\WindowsServer-2016-MS-2.1.org.default.xml"
			ManualChecks         = "C:\Users\jadean-sa\Desktop\SCAR\Resources\Stig Data\Manual Checks\WindowsServer\WindowsServer-2016-MS-2R1-ManualChecks.psd1"
			xccdfPath            = "C:\Users\jadean-sa\Desktop\SCAR\Resources\Stig Data\XCCDFs\Windows.Server.2016\U_MS_Windows_Server_2016_STIG_V2R1_Manual-xccdf.xml"
		}
	}
}
