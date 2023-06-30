function ColorText ([String]$color) {
    process { Write-Host $_ -ForegroundColor $color }
}

function DisplayInfo {
    Write-Host
    "**************" | ColorText("blue")
    "GREPLOOP" | ColorText("yellow")
    Write-Host
    "Type \q to break loop or press CTRL+c" | ColorText("green")
    "**************" | ColorText("blue")
    Write-Host
}

DisplayInfo

for (;;) {
    $userInput = Read-Host "Search string"
    if ($userInput -eq "\q"){break}
    if ($userInput -eq "\i"){
        DisplayInfo
        continue
    }
    Select-String -Pattern $userInput -Path "./*.txt" | ColorText("green")
}

