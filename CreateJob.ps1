param (
    [switch]$IsFinal
)

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$GrantType = "client_credentials"
$ClientId = "dc7e16c9-85b8-47c2-861c-0c54d5a3eec2"
$ClientSecret = "T197Q~2eoteJMIqdyfa5z2yFvYdqli87wyXkd"
$tenantId = "c88cf34a-896c-41b7-9880-66ac0bf45312"
$Scope = "api://e29099a5-3119-455e-83d1-78c796881e0a/.default"

$body = @{
 "grant_type"="$GrantType"
 "client_id"="$ClientId"
 "client_secret"="$ClientSecret"
 "scope"="$Scope"
 }

 $tokenRequestResponse = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token" -Method 'Post' -Body $body -ContentType "application/x-www-form-urlencoded"
 $token = $tokenRequestResponse.access_token

 $headers = @{
    Authorization="Bearer $token"
}

$JobRequestObject = @{}
$JobRequestObject.pipelineType = "GithubWorkflow"
$JobRequestObject.scope = "catsburg:ReleaseDocumentation"
$JobRequestObject.runId = $Env:GITHUB_RUN_ID
$JobRequestObject.isFinal = $IsFinal.IsPresent

$JobRequestJson = $(ConvertTo-Json -InputObject $JobRequestObject -Compress)
Write-Host $JobRequestJson

$JobRequestResponse = Invoke-WebRequest -Method 'Post' -Uri "https://releasedoc-api.azurewebsites.net/RunDocumentationJobs" -ContentType application/json -Headers $headers -Body $JobRequestJson

$jobUri = $JobRequestResponse.Headers.Location
write-host $jobUri

$JobStatusRequestResponse = Invoke-WebRequest -Uri $jobUri -Method GET -Headers $headers -ContentType application/json
$JobStatusRequestResponseJson  = $JobStatusRequestResponse.Content | Out-String | ConvertFrom-Json 
$Status =  $JobStatusRequestResponseJson.status
$CreatedRunId = $JobStatusRequestResponseJson.createdRunId

Write-Output $JobStatusRequestResponseJson

while($Status -ne "Completed")
     {
       $JobStatusRequestResponse = Invoke-WebRequest -Uri $JobRequestResponse.Headers.Location -Method GET -Headers $headers -ContentType application/json
       $JobStatusRequestResponseJson  = $JobStatusRequestResponse.Content | Out-String | ConvertFrom-Json 
       $Status =  $JobStatusRequestResponseJson.status
       $CreatedRunId = $JobStatusRequestResponseJson.createdRunId
       Write-Output $Status

       Start-Sleep -s 1
     }


Write-Output "https://releasedoc.azurewebsites.net/Runs/$CreatedRunId"
