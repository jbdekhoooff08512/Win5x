# Test script for Referral and Gift Code endpoints
$baseUrl = "http://localhost:3001"
$testUser = $null
$testAdmin = $null
$testGiftCode = $null

function Test-Endpoint {
    param(
        [string]$Method,
        [string]$Url,
        [hashtable]$Headers = @{},
        [string]$Body = $null
    )
    
    try {
        $params = @{
            Method = $Method
            Uri = $Url
            Headers = $Headers
        }
        
        if ($Body) {
            $params.Body = $Body
            $params.ContentType = "application/json"
        }
        
        $response = Invoke-WebRequest @params
        return @{
            StatusCode = $response.StatusCode
            Content = $response.Content | ConvertFrom-Json
        }
    }
    catch {
        return @{
            StatusCode = $_.Exception.Response.StatusCode.value__
            Content = $_.Exception.Response | ConvertFrom-Json
        }
    }
}

Write-Host "=== Testing User Registration ===" -ForegroundColor Green
$userData = @{
    username = "testuser$(Get-Date -Format 'yyyyMMddHHmmss')"
    email = "testuser$(Get-Date -Format 'yyyyMMddHHmmss')@example.com"
    password = "password123"
} | ConvertTo-Json

$response = Test-Endpoint -Method POST -Url "$baseUrl/api/auth/register" -Body $userData
Write-Host "Status: $($response.StatusCode)"
Write-Host "Response: $($response.Content | ConvertTo-Json -Depth 3)"

if ($response.StatusCode -eq 201) {
    $testUser = $response.Content.data.user
    Write-Host "✅ User registered successfully" -ForegroundColor Green
} else {
    Write-Host "❌ User registration failed" -ForegroundColor Red
}

Write-Host "`n=== Testing User Login ===" -ForegroundColor Green
if ($testUser) {
    $loginData = @{
        username = $testUser.username
        password = "password123"
    } | ConvertTo-Json
    
    $response = Test-Endpoint -Method POST -Url "$baseUrl/api/auth/login" -Body $loginData
    Write-Host "Status: $($response.StatusCode)"
    Write-Host "Response: $($response.Content | ConvertTo-Json -Depth 3)"
    
    if ($response.StatusCode -eq 200) {
        $testUser = $testUser + $response.Content.data
        Write-Host "✅ User login successful" -ForegroundColor Green
    } else {
        Write-Host "❌ User login failed" -ForegroundColor Red
    }
}

Write-Host "`n=== Testing Admin Login ===" -ForegroundColor Green
$adminData = @{
    username = "superadmin"
    password = "superadmin123"
} | ConvertTo-Json

$response = Test-Endpoint -Method POST -Url "$baseUrl/api/auth/login" -Body $adminData
Write-Host "Status: $($response.StatusCode)"
Write-Host "Response: $($response.Content | ConvertTo-Json -Depth 3)"

if ($response.StatusCode -eq 200) {
    $testAdmin = $response.Content.data
    Write-Host "✅ Admin login successful" -ForegroundColor Green
} else {
    Write-Host "❌ Admin login failed" -ForegroundColor Red
}

Write-Host "`n=== Testing Gift Code Creation ===" -ForegroundColor Green
if ($testAdmin) {
    $giftCodeData = @{
        code = "TEST$(Get-Date -Format 'yyyyMMddHHmmss')"
        amount = 100
        usageLimit = 5
        expiryDate = (Get-Date).AddDays(30).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    } | ConvertTo-Json
    
    $headers = @{
        "Authorization" = "Bearer $($testAdmin.accessToken)"
    }
    
    $response = Test-Endpoint -Method POST -Url "$baseUrl/api/gift-code/admin/gift-codes" -Headers $headers -Body $giftCodeData
    Write-Host "Status: $($response.StatusCode)"
    Write-Host "Response: $($response.Content | ConvertTo-Json -Depth 3)"
    
    if ($response.StatusCode -eq 201) {
        $testGiftCode = $response.Content.data
        Write-Host "✅ Gift code created successfully" -ForegroundColor Green
    } else {
        Write-Host "❌ Gift code creation failed" -ForegroundColor Red
    }
}

Write-Host "`n=== Testing Gift Code Redemption ===" -ForegroundColor Green
if ($testUser -and $testGiftCode) {
    $redemptionData = @{
        code = $testGiftCode.code
    } | ConvertTo-Json
    
    $headers = @{
        "Authorization" = "Bearer $($testUser.accessToken)"
    }
    
    $response = Test-Endpoint -Method POST -Url "$baseUrl/api/gift-code/user/redeem-code" -Headers $headers -Body $redemptionData
    Write-Host "Status: $($response.StatusCode)"
    Write-Host "Response: $($response.Content | ConvertTo-Json -Depth 3)"
    
    if ($response.StatusCode -eq 200) {
        Write-Host "✅ Gift code redeemed successfully" -ForegroundColor Green
    } else {
        Write-Host "❌ Gift code redemption failed" -ForegroundColor Red
    }
}

Write-Host "`n=== Testing Duplicate Gift Code Redemption ===" -ForegroundColor Green
if ($testUser -and $testGiftCode) {
    $redemptionData = @{
        code = $testGiftCode.code
    } | ConvertTo-Json
    
    $headers = @{
        "Authorization" = "Bearer $($testUser.accessToken)"
    }
    
    $response = Test-Endpoint -Method POST -Url "$baseUrl/api/gift-code/user/redeem-code" -Headers $headers -Body $redemptionData
    Write-Host "Status: $($response.StatusCode)"
    Write-Host "Response: $($response.Content | ConvertTo-Json -Depth 3)"
    
    if ($response.StatusCode -eq 400) {
        Write-Host "✅ Duplicate redemption properly rejected" -ForegroundColor Green
    } else {
        Write-Host "❌ Duplicate redemption should have been rejected" -ForegroundColor Red
    }
}

Write-Host "`n=== Testing Referral Stats ===" -ForegroundColor Green
if ($testUser) {
    $headers = @{
        "Authorization" = "Bearer $($testUser.accessToken)"
    }
    
    $response = Test-Endpoint -Method GET -Url "$baseUrl/api/invitation/stats" -Headers $headers
    Write-Host "Status: $($response.StatusCode)"
    Write-Host "Response: $($response.Content | ConvertTo-Json -Depth 3)"
    
    if ($response.StatusCode -eq 200) {
        Write-Host "✅ Referral stats retrieved successfully" -ForegroundColor Green
    } else {
        Write-Host "❌ Referral stats retrieval failed" -ForegroundColor Red
    }
}

Write-Host "`n=== Testing User Wallet Balance ===" -ForegroundColor Green
if ($testUser) {
    $headers = @{
        "Authorization" = "Bearer $($testUser.accessToken)"
    }
    
    $response = Test-Endpoint -Method GET -Url "$baseUrl/api/user/wallets" -Headers $headers
    Write-Host "Status: $($response.StatusCode)"
    Write-Host "Response: $($response.Content | ConvertTo-Json -Depth 3)"
    
    if ($response.StatusCode -eq 200) {
        Write-Host "✅ Wallet balance retrieved successfully" -ForegroundColor Green
    } else {
        Write-Host "❌ Wallet balance retrieval failed" -ForegroundColor Red
    }
}

Write-Host "`n=== All Tests Completed ===" -ForegroundColor Yellow
