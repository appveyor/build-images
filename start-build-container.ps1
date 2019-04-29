Param(
  [Parameter(Mandatory=$true)]
  [string]$token,

  [Parameter(Mandatory=$true)]
  [string]$branch,

  [Parameter(Mandatory=$false)]
  [string]$commitId,
  
  [Parameter(Mandatory=$false)]
  [string]$SKIP_TEMPLATE,
  
  [Parameter(Mandatory=$false)]
  [string]$SKIP_CLOUD  
)

$headers = @{
  "Authorization" = "Bearer $token"
  "Content-type" = "application/json"
}

if ($commitId -eq "") {
  $body = @{
    accountName="AppVeyor"
    projectSlug="build-container"
    branch=$branch
  }
}
else {
  $body = @{
    accountName="AppVeyor"
    projectSlug="build-container"
    branch=$branch
    commitId=$commitId
  }
}

$environmentVariables = ""

if ($SKIP_TEMPLATE -ne "") {
  $environmentVariables = @{
  SKIP_TEMPLATE=$SKIP_TEMPLATE 
 }
}

if ($SKIP_CLOUD -ne "") {
  $environmentVariables = @{
  SKIP_CLOUD=$SKIP_CLOUD 
  }
}

if ($SKIP_TEMPLATE -ne "" -and $SKIP_CLOUD -ne "") {
  $environmentVariables = @{
  SKIP_TEMPLATE=$SKIP_TEMPLATE
  SKIP_CLOUD=$SKIP_CLOUD
  }
}

if ($environmentVariables -ne "") {
  $body.Add("environmentVariables", $environmentVariables)
}

$body = $body | ConvertTo-Json

Invoke-RestMethod -Uri 'https://ci.appveyor.com/api/builds' -Headers $headers  -Body $body -Method PO