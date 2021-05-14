# STIG Compliance Automation Repository (SCAR)
___
## What is SCAR?
___
**SCAR** is a framework for managing and deploying STIG-compliant DSC Configurations at scale within an existing Active Directory environment. SCAR with scan the environment, identify applicable STIGs, build PowerSTIG configurationdata for each machine, automates the generation for ATO/CCRI documentation thorugh STIG Checklists, and is also capable of parsing/reporting STIG compliance via PowerBI. SCAR accelerates STIG compliance and cloud readiness by building a customizable infrastructure as code platform.
___
## Folder Structure
___
### NodeData

The NodeData folder stores Powershell Data files that represent the end nodes that you are targetting. Each NodeData .psd1 file should contain the following:

* NodeName - The Active Directory Computer Name of the end node. This is used by DSC to push the configuration MOF to that machine.
* LocalConfigurationManager Hashtable - Define the Local Configuration Manager settings for your end node(s).
* AppliedConfigurations Array - Define which configurations you want to apply to your end node(s).
* Parameter Hashtables - Use hashtables with Parameter values for each configuration you're applying.

### Configurations

Standardized configuration scripts should be located in the Configurations folder. Follow these guidlines for your configurations:

* Each configuration should be named the exact same as the file name.
* Use parameters for settings that allow for variance.

### MOFs

Once you run the Start-DscBuild function, the configurations for each defined node will be compiled and executed to generate MOFs for DSC settings and Meta.MOFs for LCM settings. Target this folder with Start-DSCConfiguration to push the compiled/generated configurations to every node.

### Artifacts

Once you run the Start-DscBuild funtion, the configurations for each defined node will be compiled into their own individual configuration scripts which will be exported into the artifacts folder for reference.

### Resources

The resources folder is used to store Powershell Modules, DSC Resource Modules, helper functions, etc that are relevent to your organization.

Build/Release functions for DSCSM are also stored in the resources folder.
___
## Code of Conduct
___
This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/)
or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions
or comments.
___
## How to Contribute
___
We welcome all contributions to the development of DSCSM.
There are several different ways you can help.
You can add new configurations, add test automation, improve documentation, fix existing issues, or open new ones.
See our [contributing guide](README.CONTRIBUTING.md) for more info on how to become a contributor.

___
## Project Contributors
___
* Jake Dean [@JakeDean3631](https://github.com/JakeDean3631)
* Ken Johnson   [@kenjohnson03](https://github.com/kenjohnson03)
* Cody Aldrich  [@coaldric](https://github.com/coaldric)

## Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit https://cla.opensource.microsoft.com.

When you submit a pull request, a CLA bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## Trademarks

This project may contain trademarks or logos for projects, products, or services. Authorized use of Microsoft 
trademarks or logos is subject to and must follow 
[Microsoft's Trademark & Brand Guidelines](https://www.microsoft.com/en-us/legal/intellectualproperty/trademarks/usage/general).
Use of Microsoft trademarks or logos in modified versions of this project must not cause confusion or imply Microsoft sponsorship.
Any use of third-party trademarks or logos are subject to those third-party's policies.
