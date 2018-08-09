
@{
    RootModule        = 'v[[MAJOR]]\VstsRestApiClient.psm1';
    Description       = 'This modules serves as a client to the VSTS Rest Api.'
    ModuleVersion     = '[[MAJOR]].[[MINOR]].[[PATCH]]';
    GUID              = 'f2286125-3d21-4acc-9673-d5fb04bdc0e2';
    Author            = 'Guillermo Alicea';
    Copyright         = '(c) 2018 Guillermo Alicea. All rights reserved.'
    FunctionsToExport = '*';
    CmdletsToExport   = '*';
    VariablesToExport = '*';
    AliasesToExport   = @();
    RequiredModules   = @();
    PrivateData = @{
        PSData = @{
            Tags         = @('Vsts', 'Tfs', 'Client', 'Api')
            LicenseUri   = 'https://github.com/PoshTamer/VstsRestApiClient/blob/master/LICENSE'
            ProjectUri   = 'https://github.com/PoshTamer/VstsRestApiClient/blob/master'
            IconUri      = 'https://raw.github.com/PoshTamer/VstsRestApiClient/blob/master/LICENSE/imgs/icons/v[[MAJOR]]/icon.ico'
            CommitHash   = '[[COMMIT_HASH]]'
        }
    }
    DefaultCommandPrefix = 'Vsts'
}