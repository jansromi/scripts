class Host {
    [Int]$HostId
    [String]$Username
    [String]$IpAddress
    [String]$Nickname

    # Construct Host-object from a string
    # parse regexp: "(^*?)\s*, \s*(.*),\s*(.*)$"
    # where group1: "(^*?)\s*," captures chars before 1st comma,
    #       group2: "\s*(.*)," captures chars before 2nd comma,
    #       group3: "\s*(.*)," captures chars before 3rd comma
    #       group4: "\s*(.*)$" captures chars until line end
    # 
    Host([String]$dataToParse) {
        $parseCommaSepValues = "(^.*?)\s*,\s*(.*), \s*(.*), \s*(.*)$";
        if ($dataToParse -match $parseCommaSepValues) {
            $this.HostId = $matches[1].Trim()
            $this.Username = $matches[2].Trim()
            $this.IpAddress = $matches[3].Trim()
            $this.Nickname = $matches[4].Trim()
        }
    }
}
$HostData = Get-Content -Path .\hosts.txt

[Host[]]$Hosts = [Host[]]::new($HostData.Length)

for ($i = 0; $i -lt $HostData.Length; $i++) {
    $Hosts[$i] = [Host]::new($HostData[$i])
}

Write-Host "SSH HOSTS:"

foreach ($SingleHost in $Hosts){
    Write-Host $SingleHost.HostId ": " -ForegroundColor yellow -NoNewline;
    Write-Host $SingleHost.Nickname -ForegroundColor Green;    
}

$selectedHost = Read-Host "Select a host to continue"

foreach ($SingleHost in $Hosts){
    if ($SingleHost.HostId -eq $selectedHost) {
        ssh ("{0}@{1}" -f $SingleHost.Username, $SingleHost.IpAddress)
    }
}


