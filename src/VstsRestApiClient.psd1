
@{
    RootModule        = 'VstsRestApiClient.psm1';
    Description       = 'This module serves as a client to the VSTS Rest Api.'
    ModuleVersion     = '1.0.101';
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
            IconUri      = 'https://raw.github.com/PoshTamer/VstsRestApiClient/blob/master/imgs/icons/icon.ico'
            CommitHash   = '[[COMMIT_HASH]]'
        }
    }
    DefaultCommandPrefix = 'Vsts'
}

