@{
	NodeName = "vm-dc-001"

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

		PowerSTIG_WindowsDNSServer =
		@{
			OsVersion            = "2016"
			xccdfPath            = "C:\Users\jadean-sa\Desktop\SCAR\Resources\Stig Data\XCCDFs\Windows.Dns\U_Microsoft_Windows_2012_Server_DNS_STIG_V2R1_Manual-xccdf.xml"
			OrgSettings          = "C:\Users\jadean-sa\Desktop\SCAR\Resources\Stig Data\Organizational Settings\WindowsDnsServer-2012R2-2.1.org.default.xml"
			ManualChecks         = "C:\Users\jadean-sa\Desktop\SCAR\Resources\Stig Data\Manual Checks\WindowsDnsServer\WindowsDnsServer-2R1-ManualChecks.psd1"
		}

		PowerSTIG_WindowsDefender =
		@{
			OrgSettings          = "C:\Users\jadean-sa\Desktop\SCAR\Resources\Stig Data\Organizational Settings\WindowsDefender-All-2.1.org.default.xml"
			ManualChecks         = "C:\Users\jadean-sa\Desktop\SCAR\Resources\Stig Data\Manual Checks\WindowsDefender\WindowsDefender-1R4-ManualChecks.psd1"
			xccdfPath            = "C:\Users\jadean-sa\Desktop\SCAR\Resources\Stig Data\XCCDFs\Windows.Defender\U_MS_Windows_Defender_Antivirus_STIG_V2R1_Manual-xccdf.xml"
		}

		PowerSTIG_WindowsServer =
		@{
			OSRole               = "DC"
			OsVersion            = "2016"
			OrgSettings          = "C:\Users\jadean-sa\Desktop\SCAR\Resources\Stig Data\Organizational Settings\WindowsServer-2016-DC-2.1.org.default.xml"
			ManualChecks         = "C:\Users\jadean-sa\Desktop\SCAR\Resources\Stig Data\Manual Checks\WindowsServer\WindowsServer-2016-DC-2R1-ManualChecks.psd1"
			xccdfPath            = "C:\Users\jadean-sa\Desktop\SCAR\Resources\Stig Data\XCCDFs\Windows.Server.2016\U_MS_Windows_Server_2016_STIG_V2R1_Manual-xccdf.xml"
		}
	}
}
