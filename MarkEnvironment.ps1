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

$RequestObject = @{}

$RequestObject.pipelineType  = "GithubWorkflow"
$RequestObject.pipelineScope  = $Env:GITHUB_REPOSITORY
$RequestObject.sourceSystemId  = $Env:GITHUB_RUN_ID
$RequestObject.productionStageIdentifier  = $Env:GITHUB_JOB
$RequestJson = $(ConvertTo-Json -InputObject $RequestObject -Compress)

$RequestResponse = Invoke-WebRequest -Method 'Post' -Uri "https://releasedoc-api.azurewebsites.net/Runs/MarkProductionStage" -ContentType application/json -Headers $headers -Body $RequestJson
$RequestResponseJson  = $RequestResponse.Content | Out-String | ConvertFrom-Json


Write-Output $RequestResponseJson
