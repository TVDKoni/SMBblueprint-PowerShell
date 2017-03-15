@{

    RootModule = 'FlexdeskBlueprint.psm1';

    ModuleVersion = '8.0.0.3';

    GUID = '2f47c9fb-d226-49f2-b5bf-4b6999c06644';

    Author = 'Konrad Brunner';

    CompanyName = 'Trivadis Services AG';

    Copyright = '(c) 2016 Inovativ BE, 2017 Trivadis Services CH. All rights reserved.';

    Description = 'Deployment Framework for the Flexdesk solution.';

    PowerShellVersion = '4.0';

    FunctionsToExport = '*'

    RequiredModules = @(
@{ModuleName="Microsoft.Online.SharePoint.PowerShell";ModuleVersion="16.0.5806.0";Guid="adedde5f-e77b-4682-ab3d-a4cb4ff79b83"},
@{ModuleName="AzureRM.Profile";ModuleVersion="1.0.11";Guid="342714fc-4009-4863-8afb-a9067e3db04b"},
@{ModuleName="AzureRM.Resources";ModuleVersion="1.0.11";Guid="ab3ca893-26fe-44b0-bd3c-8933df144d7b"},
@{ModuleName="MSOnline";ModuleVersion="1.0";Guid="d162594e-d7aa-42be-9884-84928d3f7acf"},
@{ModuleName="AzureRM.Network";ModuleVersion="3.0.0";Guid="eb75c732-e274-4a20-b502-e9958e63484a"}
)

    PrivateData = @{

    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
        Tags = @('Flexdesk','SMB','Office365','Azure','AzureRM')

        # A URL to the license for this module.
        # LicenseUri = ''

        # A URL to the main website for this project.
        ProjectUri = 'https://github.com/TVDKoni/SMBblueprint-PowerShell'

        # A URL to an icon representing this module.
        # IconUri = ''

        # ReleaseNotes of this module
        ReleaseNotes = @(
            '0.0.0.1: Initial preview, not production ready!',
            '0.0.0.3: Publishing test with VSO build automation. Logging capabilities optimized. Added -MailDomain switch to Office Deployment function.',
            '0.0.0.4: Publishing test with VSO build automation. Logging capabilities optimized. Added -MailDomain switch to Office Deployment function.',
            '0.0.0.5: Added missing AzureRM.Network requirement. Added additional checks for Azure Public DNS reserved keyword policy',
            '0.0.0.6: Fixed VM start/stop automation issues: Schedules are now enabled from the day after deployment / Variable<->Tag mismatch resolved / centralized the template URL in the ARM structure'
            '0.0.0.7: Added Multi-Region / Server 2016 support'
            '0.0.0.7: Check https://inovativ.github.io/SMBblueprint-Docs/'
        )
        ExternalModuleDependencies = @('Microsoft.Online.SharePoint.PowerShell')

    } # End of PSData hashtable

} # End of PrivateData hashtable
}