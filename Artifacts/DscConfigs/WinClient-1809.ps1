Configuration MainConfig
{
	Node $AllNodes.Where{$_.NodeName -eq "WinClient-1809"}.NodeName
	{	}
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