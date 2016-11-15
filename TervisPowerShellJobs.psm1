function Start-ParallelWork {
    param (
        $ScriptBlock,
        $Parameters,
        $MaxConcurrentJobs = 10
    )
    $Jobs = @()

    foreach ($Parameter in $Parameters) {
        while ($(Get-Job -State Running | where Id -In $Jobs.Id | Measure).count -ge $MaxConcurrentJobs) { Start-Sleep -Milliseconds 100 }
        $Jobs += Start-Job -ScriptBlock $ScriptBlock -ArgumentList $Parameter
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