@{
	NodeName = "VM-WS-001"

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

		PowerSTIG_Firefox =
		@{
			InstallDirectory      = "C:\Program Files\Mozilla Firefox"
			xccdfPath			= "C:\Users\jadean-sa\Desktop\SCAR\Resources\Stig Data\XCCDFs\browser\U_Mozilla_Firefox_V5R1_Manual-xccdf.xml"
			OrgSettings			= "C:\Users\jadean-sa\Desktop\SCAR\Resources\Stig Data\Organizational Settings\FireFox-All-4.29.org.default.xml"
			ManualChecks 		= "C:\Users\jadean-sa\Desktop\SCAR\Resources\Stig Data\Manual Checks\FireFox\FireFox-5R1-ManualChecks.psd1"
		}

		PowerSTIG_WebServer =
		@{
			SkipRule         = "V-214429"
			IISVersion       = "8.5"
			LogPath          = "C:\InetPub\Logs"
			XccdfPath        = "C:\Users\jadean-sa\Desktop\SCAR\Resources\Stig Data\XCCDFs\Web Server\U_MS_IIS_8-5_Server_STIG_V2R1_Manual-xccdf.xml"
			OrgSettings      = "C:\Users\jadean-sa\Desktop\SCAR\Resources\Stig Data\Organizational Settings\IISServer-8.5-2.1.org.default.xml"
			ManualChecks     = "C:\Users\jadean-sa\Desktop\SCAR\Resources\Stig Data\Manual Checks\WebServer\WebServer-8.5-2R1-ManualChecks.psd1"
		}

		PowerSTIG_WebSite =
		@{
			IISVersion       = "8.5"
			WebsiteName      = "Default Web Site"
			WebAppPool       = "DefaultAppPool"
			XccdfPath        = "C:\Users\jadean-sa\Desktop\SCAR\Resources\Stig Data\XCCDFs\Web Server\U_MS_IIS_8-5_Site_STIG_V2R1_Manual-xccdf.xml"
			OrgSettings      = "C:\Users\jadean-sa\Desktop\SCAR\Resources\Stig Data\Organizational Settings\IISSite-8.5-2.1.org.default.xml"
			ManualChecks     = "C:\Users\jadean-sa\Desktop\SCAR\Resources\Stig Data\Manual Checks\WebSite\Website-8.5-2R1-ManualChecks.psd1"
		}

		PowerSTIG_WindowsServer =
		@{
			OSRole               = "MS"
			OsVersion            = "2012R2"
			OrgSettings          = "C:\Users\jadean-sa\Desktop\SCAR\Resources\Stig Data\Organizational Settings\WindowsServer-2012R2-MS-3.1.org.default.xml"
			ManualChecks         = "C:\Users\jadean-sa\Desktop\SCAR\Resources\Stig Data\Manual Checks\WindowsServer\WindowsServer-2012R2-MS-3R1-ManualChecks.psd1"
			xccdfPath            = "C:\Users\jadean-sa\Desktop\SCAR\Resources\Stig Data\XCCDFs\Windows.Server.2012R2\U_MS_Windows_2012_and_2012_R2_MS_V3R1_Manual-xccdf.xml"
		}
	}
}
