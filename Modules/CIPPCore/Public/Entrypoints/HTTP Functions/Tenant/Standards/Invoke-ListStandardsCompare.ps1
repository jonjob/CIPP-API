using namespace System.Net

function Invoke-ListStandardsCompare {
    <#
    .FUNCTIONALITY
        Entrypoint
    .ROLE
        Tenant.BestPracticeAnalyser.Read
    #>
    [CmdletBinding()]
    param($Request, $TriggerMetadata)


    $Table = Get-CIPPTable -TableName 'CippStandardsReports'
    $TenantFilter = $Request.Query.tenantFilter
    if ($TenantFilter) {
        $Table.Filter = "RowKey eq '{0}'" -f $TenantFilter
    }

    $Results = Get-CIPPAzDataTableEntity @Table

    #in the results we have objects starting with "standards." All these have to be converted from JSON. Do not do this is its a boolean
    $Results | ForEach-Object {
        $Object = $_
        $Object.PSObject.Properties | ForEach-Object {
            if ($_.Name -like 'standards_*') {
                if ($_.Value -is [System.Boolean]) {
                    $_.Value = [bool]$_.Value
                } elseif ($_.Value -like '*{*') {
                    $_.Value = ConvertFrom-Json -InputObject $_.Value -ErrorAction SilentlyContinue
                } else {
                    $_.Value = [string]$_.Value
                }

                $Key = $_.Name.replace('standards_', 'standards.')
                $Key = $Key.replace('IntuneTemplate_', 'IntuneTemplate.')
                $Key = $Key -replace '__', '-'

                $object | Add-Member -MemberType NoteProperty -Name $Key -Value $_.Value -Force
                $object.PSObject.Properties.Remove($_.Name)
            }
        }
    }


    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
            StatusCode = [HttpStatusCode]::OK
            Body       = @($Results)
        })

}
