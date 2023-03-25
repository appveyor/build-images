function Get-IPs {

    Param(
        [Parameter(Mandatory = $true)]
        [array] $Subnets
    )

    foreach ($subnet in $subnets) {
        $ip1 = ''
        $ip2 = ''
        $ip3 = ''

        #Split IP and subnet
        $IP = ($Subnet -split "\/")[0]
        $SubnetBits = ($Subnet -split "\/")[1]
        if ($SubnetBits -eq "32") {
            $IP
        }
        else {
            #Convert IP into binary
            #Split IP into different octects and for each one, figure out the binary with leading zeros and add to the total
            $Octets = $IP -split "\."
            $IPInBinary = @()
            foreach ($Octet in $Octets) {
                #convert to binary
                $OctetInBinary = [convert]::ToString($Octet, 2)

                #get length of binary string add leading zeros to make octet
                $OctetInBinary = ("0" * (8 - ($OctetInBinary).Length) + $OctetInBinary)

                $IPInBinary = $IPInBinary + $OctetInBinary
            }
            $IPInBinary = $IPInBinary -join ""

            #Get network ID by subtracting subnet mask
            $HostBits = 32 - $SubnetBits
            $NetworkIDInBinary = $IPInBinary.Substring(0, $SubnetBits)

            #Get host ID and get the first host ID by converting all 1s into 0s
            $HostIDInBinary = $IPInBinary.Substring($SubnetBits, $HostBits)
            $HostIDInBinary = $HostIDInBinary -replace "1", "0"

            #Work out all the host IDs in that subnet by cycling through $i from 1 up to max $HostIDInBinary (i.e. 1s stringed up to $HostBits)
            #Work out max $HostIDInBinary
            $imax = [convert]::ToInt32(("1" * $HostBits), 2) - 1

            $IPs = @()

            #Next ID is first network ID converted to decimal plus $i then converted to binary
            For ($i = 1 ; $i -le $imax ; $i++) {
                #Convert to decimal and add $i
                $NextHostIDInDecimal = ([convert]::ToInt32($HostIDInBinary, 2) + $i)
                #Convert back to binary
                $NextHostIDInBinary = [convert]::ToString($NextHostIDInDecimal, 2)
                #Add leading zeros
                #Number of zeros to add
                $NoOfZerosToAdd = $HostIDInBinary.Length - $NextHostIDInBinary.Length
                $NextHostIDInBinary = ("0" * $NoOfZerosToAdd) + $NextHostIDInBinary

                #Work out next IP
                #Add networkID to hostID
                $NextIPInBinary = $NetworkIDInBinary + $NextHostIDInBinary
                #Split into octets and separate by . then join
                $IP = @()
                For ($x = 1 ; $x -le 4 ; $x++) {
                    #Work out start character position
                    $StartCharNumber = ($x - 1) * 8
                    #Get octet in binary
                    $IPOctetInBinary = $NextIPInBinary.Substring($StartCharNumber, 8)
                    #Convert octet into decimal
                    $IPOctetInDecimal = [convert]::ToInt32($IPOctetInBinary, 2)
                    #Add octet to IP
                    $IP += $IPOctetInDecimal
                }

                if ($ip1 -ne $IP[0] -or $ip2 -ne $IP[1] -or $ip3 -ne $IP[2]) {
                    $IP[3] = '*'
                    $ip1 = $IP[0]
                    $ip2 = $IP[1]
                    $ip3 = $IP[2]

                    #Separate by .
                    $IP = $IP -join "."
                    $IPs += $IP
                }
            }
            $IPs -join ","
        }
    }
}


Write-Host "Adding SSH known hosts..." -ForegroundColor Cyan
$sshPath = Join-Path $Home ".ssh"
if (-not (Test-Path $sshPath)) {
    New-Item $sshPath -ItemType directory -Force
}

$contents = @()
# GitHub IP addresses
$gitHubMetaJson = (Invoke-WebRequest 'https://api.github.com/meta').Content
$GithubIPs = (ConvertFrom-Json $gitHubMetaJson).git | Where-Object { $_.indexOf(':') -eq -1 }

Get-IPs -subnets $GithubIPs | ForEach-Object {
    $contents += "github.com,$_ ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCj7ndNxQowgcQnjshcLrqPEiiphnt+VTTvDP6mHBL9j1aNUkY4Ue1gvwnGLVlOhGeYrnZaMgRK6+PKCUXaDbC7qtbW8gIkhL7aGCsOr/C56SJMy/BCZfxd1nWzAOxSDPgVsmerOBYfNqltV9/hWCqBywINIR+5dIg6JTJ72pcEpEjcYgXkE2YEFXV1JHnsKgbLWNlhScqb2UmyRkQyytRLtL+38TGxkxCflmO+5Z8CSSNY7GidjMIZ7Q4zMjA2n1nGrlTDkzwDCsw+wqFPGQA179cnfGWOWRVruj16z6XyvxvjJwbz0wQZ75XK5tKSb7FNyeIEs4TT4jk+S4dhPeAUC5y+bDYirYgM4GC7uEnztnZyaVWQ7B381AK4Qdrwt51ZqExKbQpTUNn+EjqoTwvqNj4kqx5QUCI0ThS/YkOxJCXmPUWZbhjpCg56i+2aB6CmK2JGhn57K5mj0MNdBXA4/WnwH6XoPWJzK5Nyu2zB3nAZp+S5hpQs+p1vN1/wsjk="
    $contents += "github.com,$_ ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBEmKSENjQEezOmxkZMy7opKgwFB9nkt5YRrYMjNuG5N87uRgg6CLrbo5wAdT/y6v0mKV0U2w0WZ2YB/++Tpockg="
    $contents += "github.com,$_ ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl"
}

# BitBucket
$bitbucketHubMetaJson = (Invoke-WebRequest 'https://ip-ranges.atlassian.com/').Content
$bitbucketIPs = (ConvertFrom-Json $bitbucketHubMetaJson).items.cidr | Where-Object { $_.indexOf(':') -eq -1 }
Get-IPs -subnets $BitBucketIPs | ForEach-Object {
    $contents += "bitbucket.org,$_ ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAubiN81eDcafrgMeLzaFPsw2kNvEcqTKl/VqLat/MaB33pZy0y3rJZtnqwR2qOOvbwKZYKiEO1O6VqNEBxKvJJelCq0dTXWT5pbO2gDXC6h6QDXCaHo6pOHGPUy+YBaGQRGuSusMEASYiWunYN0vCAI8QaXnWMXNMdFP3jHAJH0eDsoiGnLPBlBp4TNm6rYI74nMzgz3B9IikW4WVK+dc8KZJZWYjAuORU3jc1c/NPskD2ASinf8v3xnfXeukU0sJ5N6m5E8VLjObPEO+mN2t/FZTMZLiFqPWc/ALSqnMnnhwrNi2rbfg/rd/IpL8Le3pSBne8+seeFVBoGqzHM9yXw=="
}

# GitLab
$contents += "gitlab.com,* ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAfuCHKVTjquxvt6CM6tdG4SLp1Btn/nOeHHE5UOzRdf"
$contents += "gitlab.com,* ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCsj2bNKTBSpIYDEGk9KxsGh3mySTRgMtXL583qmBpzeQ+jqCMRgBqB98u3z++J1sKlXHWfM9dyhSevkMwSbhoR8XIq/U0tCNyokEi/ueaBMCvbcTHhO7FcwzY92WK4Yt0aGROY5qX2UKSeOvuP4D6TPqKF1onrSzH9bx9XUf2lEdWT/ia1NEKjunUqu1xOB/StKDHMoX4/OKyIzuS0q/T1zOATthvasJFoPrAjkohTyaDUz2LN5JoH839hViyEG82yB+MjcFV5MU3N1l1QL3cVUCh93xSaua1N85qivl+siMkPGbO5xR/En4iEY6K2XPASUEMaieWVNTRCtJ4S8H+9"
$contents += "gitlab.com,* ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBFSMqzJeV9rUzU4kWitGjeR4PWSa29SPqJ1fVkhtj3Hw9xjLVXVYrU9QlYWrOLXBpQ6KWjbjTDTdDkoohFzgbEY="

$knownhostfile = Join-Path $sshPath "known_hosts"
Write-Host "Updating $knownhostfile"
[IO.File]::WriteAllLines($knownhostfile, $contents)

Get-ChildItem $sshPath

Write-Host "Known hosts configured" -ForegroundColor Green
