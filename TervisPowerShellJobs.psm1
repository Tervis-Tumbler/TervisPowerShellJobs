#Requires -modules PoshRSJob

function Install-TervisPowerShellJobs {
    Install-Module -Scope CurrentUser PoshRSJob
}

function Start-ParallelWork {
    [CmdletBinding()]
    param (
        $ScriptBlock,
        $Parameters,
        $OptionalParameters,
        $MaxConcurrentJobs = 10
    )
    $Jobs = @()
    [Int]$Count = 0
    foreach ($Parameter in $Parameters) {
        while ($(Get-Job -State Running | where Id -In $Jobs.Id | Measure).count -ge $MaxConcurrentJobs) { Start-Sleep -Milliseconds 100 }
        $Count += 1
        Write-Verbose "Starting job # $Count Running: $((Get-Job -State Running | Measure).count) Completed: $((Get-Job -State Completed | Measure).count)"
        $Jobs += Start-Job -ScriptBlock $ScriptBlock -ArgumentList $Parameter,$OptionalParameters
    }

    while (
        Get-Job -State Running | 
        where Id -In $Jobs.Id
    ) {
        Write-Verbose "Sleeping for 100 milliseconds"
        Start-Sleep -Milliseconds 100 
    }
    
    $Results = Get-Job -HasMoreData $true | 
    where Id -In $Jobs.Id |
    Receive-Job

    Get-Job -State Completed | 
    where Id -In $Jobs.Id | 
    Remove-Job
    
    $Results
}

function Start-RSParallelWork {
    [CmdletBinding()]
    param (
        $ScriptBlock,
        $Parameters,
        $MaxConcurrentJobs = 10
    )
    $Jobs = @()
    [Int]$Count = 0
    foreach ($Parameter in $Parameters) {
        while ($(Get-RSJob -State Running | where Id -In $Jobs.Id | Measure).count -ge $MaxConcurrentJobs) { Start-Sleep -Milliseconds 100 }
        $Count += 1
        Write-Verbose "Starting job # $Count Running: $((Get-RSJob -State Running | Measure).count) Completed: $((Get-RSJob -State Completed | Measure).count)"
        $Jobs += Start-RSJob -ScriptBlock $ScriptBlock -InputObject $Parameter
    }

    while (
        Get-RSJob -State Running | 
        where Id -In $Jobs.Id
    ) {
        Write-Verbose "Sleeping for 100 milliseconds"
        Start-Sleep -Milliseconds 100 
    }
    
    $Results = Get-RSJob -HasMoreData | 
    where Id -In $Jobs.Id |
    Receive-RSJob

    Get-RSJob -State Completed | 
    where Id -In $Jobs.Id | 
    Remove-RSJob
    
    $Results
}