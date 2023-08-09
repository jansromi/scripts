
class App {
    App() {

    }

    [void] printUserInfo([Host[]]$hostArray) {
        Write-Host "SSH HOSTS:"
        Write-Host "-p <portnumber> for custom port in tunneled connections"
        Write-Host "-scp <destination/path> for SCPing files to selected host"
        
        foreach ($SingleHost in $HostArray){
            Write-Host $SingleHost.HostId ": " -ForegroundColor yellow -NoNewline;
            Write-Host $SingleHost.Nickname -ForegroundColor Green;    
        }
        
    }
}
class Host {
    [Int]$HostId
    [String]$Username
    [String]$IpAddress
    [String]$Nickname
    [String[]]$ForwardingAddress

    Host([String]$dataToParse) {
        $parseCommaSepValues = "(^.*?)\s*,\s*(.*), \s*(.*), \s*(.*)$";
        if ($dataToParse -match $parseCommaSepValues) {
            $this.HostId = [int]($matches[1].Trim())
            $this.Username = $matches[2].Trim()
            $this.IpAddress = $matches[3].Trim()
            $this.Nickname = $matches[4].Trim()
            $this.setForwardingAddress();
        }
    }

    # Sets ForwardingAddress for "custom"-named hosts
    [void] setForwardingAddress(){
        if ($this.Username -eq "custom") {
            $this.ForwardingAddress = $this.IpAddress -split " ", 2;
        }
    }

    [void] setForwardingPort([int] $userPort){
        if ($this.Username -ne "custom") {
            Write-Host "Custom port cannot be set"
            return
        }
        [String[]]$Port = $this.ForwardingAddress[0].Split(":", 2);
        $Port[0] = $userPort.toString();
        $this.ForwardingAddress[0] = $Port[0] + ":" + $Port[1];
    }
}

class Hosts {
    # Contains all the host-objects, that are parsed from the file
    [Host[]]$KnownHosts

    Hosts([Host[]]$hostData){
        $this.KnownHosts = $hostData;
    }

    # CLASS METHODS:

    <#
    Sets the port

    EXAMPLE:
    $host.ForwardingAddress[0] = 9006:127.0.0.1:8080
    $host.setForwardingPort(9007);
    $host.ForwardingAddress[0] = 9007:127.0.0.1:8080
    #>
    [void] setForwardingPort([int]$hostId, [int]$userPort) {
        foreach ($SingleHost in $this.KnownHosts){
            if ($SingleHost.HostId -eq $hostId) {
                $SingleHost.setForwardingPort($userPort);
            }
        }
    }

    <#
    Connects to matching host, defined in the hosts.txt-file.

    If host is named as custom, initialize a tunneled connection.
    #>
    [void] connectToHost([int]$selection){
        foreach ($SingleHost in $this.KnownHosts){
            if ($SingleHost.HostId -eq $selection) {
                if ($SingleHost.Username -eq "custom") {
                    Start-Process powershell -ArgumentList "ssh -L $($SingleHost.ForwardingAddress[0]) $($SingleHost.ForwardingAddress[1])"
                } else {
                    Start-Process powershell -ArgumentList "ssh $($SingleHost.Username)@$($SingleHost.IpAddress)"
                }
                return;
            }
        }
    }

    <#
    Opens a file dialog for the user to select a file for secure copy operation
    #>
    [string] selectFileForScp() {
        Add-Type -AssemblyName System.Windows.Forms
        $fileDialog = New-Object System.Windows.Forms.OpenFileDialog
        $fileDialog.ShowDialog() | Out-Null
        return $fileDialog.FileName
    }

    <#
    Secure Copy operation.
    #>
    [void] scpToHost([int]$selection, [string]$filePath, [string]$destinationPath) {
        foreach ($SingleHost in $this.KnownHosts) {
            if ($SingleHost.HostId -eq $selection) {
                $scpCommand ="scp $filePath $($SingleHost.Username)@$($SingleHost.IpAddress):$destinationPath" 
                Write-Host $scpCommand
                Invoke-Expression $scpCommand
                return;
            }
        }
    }
}

# Define the filepath to hosts-file.
$HostData = Get-Content -Path .\hosts.txt

[Host[]]$HostArray = [Host[]]::new($HostData.Length)

for ($i = 0; $i -lt $HostData.Length; $i++) {
    $HostArray[$i] = [Host]::new($HostData[$i])
}

[Hosts]$Hosts = [Hosts]::new($HostArray)
[App]$app = [App]::new()
$app.printUserInfo($HostArray)
[String]$userInput= Read-Host "Select a host to continue";

[String[]]$selectedHost = $userInput.Split(" ");
[int]$hostId = $selectedHost[0];

# if lever -p is given, custom port is the following value
[int]$resultCustomPort = $selectedHost.IndexOf("-p");
if ($resultCustomPort -ne -1) {
    $userPort = $selectedHost[$resultCustomPort + 1];
    $Hosts.setForwardingPort($hostId, $userPort);
}

# If lever -scp is given
[int]$resultScp = $selectedHost.IndexOf("-scp");
if ($resultScp -ne -1) {
    $destPath = $selectedHost[$resultScp + 1];
    if ($destPath -eq "") {
        $destPath = "/tmp";
    }
    Write-Host "Select files to SCP"
    $filepaths = ""
    while ($true) {
        $filepaths += $Hosts.selectFileForScp()
        Write-Host "Selected files: $filepaths"
        Write-Host "Add more files? Y/n"
        $moreFiles = Read-Host
        if ($moreFiles -eq "y") {
            $filepaths += " "
            continue
        }
        break
    }
    if ($filepaths -eq "") {
        Write-Host "No file was selected"
        Write-Host "Exiting..."
        Exit
    }
    $Hosts.scpToHost($hostId, $filepaths, $destPath)
}

$Hosts.connectToHost($hostID);
