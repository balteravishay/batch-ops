function Hash($textToHash, $secret)

{
    $hmacsha = New-Object System.Security.Cryptography.HMACSHA256    
    $hmacsha.key = [convert]::FromBase64String($secret) 
    [byte[]]$singnatureStringByteArray=[Text.Encoding]::UTF8.GetBytes($textToHash) 
    $compute = $hmacsha.ComputeHash($singnatureStringByteArray)
    $signature = [Convert]::ToBase64String($compute)
    return $signature;
}

# Parameters
$batch_account_name=(get-item env:AZ_BATCH_ACCOUNT_NAME).Value
$batch_region=(get-item env:AZ_BATCH_REGION).Value
$batch_key=(get-item env:AZ_BATCH_KEY).Value
$job_id=(get-item env:AZ_BATCH_JOB_ID).Value
$node_id=(get-item env:AZ_BATCH_NODE_ID).Value
$command=(get-item env:AZ_BATCH_COMMAND).Value
$command = $command.Replace('\', '\\');
$json = '{"id":"task' + $node_id + '", "commandLine":"cmd /c \"' + $command + '\"","userIdentity":{"autoUser":{"scope":"task","elevationLevel":"admin"}}}' 
Write-Output $json;
$base_url="https://{0}.{1}.batch.azure.com" -f $batch_account_name, $batch_region
$path="/jobs/{0}/tasks?api-version=2018-03-01.6.1" -f $job_id

# Create Signature for Authentication
 # Time in GMT
$resourceTz = [System.TimeZoneInfo]::FindSystemTimeZoneById(([System.TimeZoneInfo]::Local).Id)
[string]$date = Get-Date ([System.TimeZoneInfo]::ConvertTimeToUtc((Get-Date).ToString(),$resourceTz)) -Format r
$signature="POST`n`n`n{3}`n`napplication/json; odata=minimalmetadata; charset=utf-8`n`n`n`n`n`n`nocp-date:{0}`n/{1}/jobs/{2}/tasks`napi-version:2018-03-01.6.1" -f $date, $batch_account_name, $job_id, $json.Length
$hash = Hash $signature $batch_key

# Send Post request to reboot VM
$Url = "{0}{1}" -f $base_url, $path
$Headers = @{}
$AuthorizeHeader = "SharedKey {0}:{1}" -f $batch_account_name, $hash
$Headers.Add('Authorization',$AuthorizeHeader)
$Headers.Add('ocp-date', $date)

Invoke-RestMethod -Method 'Post' -Uri $url -Headers $Headers -ContentType "application/json; odata=minimalmetadata; charset=utf-8" -Body $json
