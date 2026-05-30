<#
.SYNOPSIS
    Query common DNS records for a domain using Resolve-DnsName.

.DESCRIPTION
    Retrieves one or more DNS record types and displays the results
    in a simple, human-readable format.

    Supported record types:

        A
        AAAA
        CNAME
        MX
        NS
        SOA
        TXT

.PARAMETER Domain
    Domain name to query.

    Default:
        google.com

.PARAMETER Server
    Optional DNS server to query.

    Examples:

        8.8.8.8
        1.1.1.1
        9.9.9.9

.PARAMETER Type
    One or more DNS record types.

    Default:

        A
        AAAA
        CNAME
        MX
        NS
        SOA
        TXT

.EXAMPLE
    .\DNSRecords.ps1

    Query all supported record types for google.com.

.EXAMPLE
    .\DNSRecords.ps1 -Domain openai.com

    Query all supported record types for openai.com.

.EXAMPLE
    .\DNSRecords.ps1 -Domain openai.com -Type A

    Query A records only.

.EXAMPLE
    .\DNSRecords.ps1 -Domain openai.com -Type A,MX,TXT

    Query multiple record types.

.EXAMPLE
    .\DNSRecords.ps1 -Domain openai.com -Server 8.8.8.8

    Query using Google's public DNS server.

.EXAMPLE
    .\DNSRecords.ps1 -Domain openai.com -Server 1.1.1.1 -Type MX

    Query MX records using Cloudflare DNS.

.NOTES
    Author: ESO-RES

    Requirements:
        - Windows 8 / Windows Server 2012 or newer
        - PowerShell 4.0+
        - Resolve-DnsName available

    Legacy compatibility version:
        win8DNSRecords.bat

    Modern version:
        DNSRecords.ps1
#>

param(
    [string]$Domain = "google.com",

    [string]$Server,

    [ValidateSet("A", "AAAA", "CNAME", "MX", "NS", "SOA", "TXT")]
    [string[]]$Type = @("A", "AAAA", "CNAME", "MX", "NS", "SOA", "TXT")
)

$Dash = "-" * 36

function Format-DnsRecord {
    param(
        [object]$Record,
        [string]$RecordType
    )

    switch ($RecordType) {
        "A" {
            $Record.IPAddress
        }

        "AAAA" {
            $Record.IPAddress
        }

        "CNAME" {
            $Record.NameHost
        }

        "MX" {
            "$($Record.Preference) $($Record.NameExchange)"
        }

        "NS" {
            $Record.NameHost
        }

        "SOA" {
            $minimum = if ($null -ne $Record.MinimumTTL) {
                $Record.MinimumTTL
            }
            else {
                $Record.MinimumTimeToLive
            }

            "$($Record.PrimaryServer) $($Record.ResponsiblePerson) $($Record.SerialNumber) $($Record.Refresh) $($Record.Retry) $($Record.Expire) $minimum"
        }

        "TXT" {
            $Record.Strings -join " "
        }

        default {
            $Record | Out-String
        }
    }
}

foreach ($t in $Type) {
    $recordType = $t.ToUpper()

    Write-Host ""
    Write-Host "Record response $recordType"
    Write-Host $Dash

    try {
        $dnsParams = @{
            Name        = $Domain
            Type        = $recordType
            ErrorAction = 'Stop'
        }

        if ($Server) {
            $dnsParams["Server"] = $Server
        }

        $results = Resolve-DnsName @dnsParams

        if ($results) {
            foreach ($record in $results) {
                $formatted = Format-DnsRecord -Record $record -RecordType $recordType

                if ($formatted) {
                    Write-Host $formatted
                }
            }
        }
        else {
            Write-Host "No records found"
        }
    }
    catch {
        if (
            $_.Exception.Message -match "DNS name does not exist" -or
            $_.Exception.Message -match "No records.*found"
        ) {
            Write-Host "No records found"
        }
        else {
            Write-Host "Error: $($_.Exception.Message)"
        }
    }
}
