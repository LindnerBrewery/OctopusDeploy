function Get-CertificatesFromUrl {
    param (
        [String]$hostname
    )
    $Callback = { param($sender, $cert, $chain, $errors) return $true };
    $request = [System.Net.Sockets.TcpClient]::new($hostname, '443');
    $stream = [System.Net.Security.SslStream]::new($request.GetStream(), $true, $Callback);
    $stream.AuthenticateAsClient($hostname);
    $chain = [System.Security.Cryptography.X509Certificates.X509Chain]::new();
    $chain.ChainPolicy.RevocationMode = [System.Security.Cryptography.X509Certificates.X509RevocationMode]::NoCheck;
    $chain.ChainPolicy.VerificationFlags = [System.Security.Cryptography.X509Certificates.X509VerificationFlags]::AllowUnknownCertificateAuthority;
    $chain.Build($stream.RemoteCertificate) | Out-Null;
    $chain.Build($stream.RemoteCertificate) | Out-Null;
    $chain.ChainElements.Certificate
}

function Import-X509Certificate {
    param (
        [System.Security.Cryptography.X509Certificates.X509Certificate2[]]$X509Certificate,
        [switch]$ChainOnly,
        [switch]$WindowsOrDotNet,
        [switch]$CaCerts
    )
    if ($ChainOnly.IsPresent) {
        if ($X509Certificate.count -gt 1) {
            $X509Certificate = $X509Certificate[1..$X509Certificate.length]
        }
    }
    if ($WindowsOrDotNet.IsPresent) {
        # choose store depending on elevation
        if ($PSVersionTable.Platform -eq 'Win32NT') {
            if (([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
                $storeLocation = [System.Security.Cryptography.X509Certificates.StoreLocation]::LocalMachine
            }
            else {
                $storeLocation = [System.Security.Cryptography.X509Certificates.StoreLocation]::CurrentUser
            }
        }

        #On Linux
        if ($PSVersionTable.Platform -eq 'Unix') {
            if ((id -u) -eq 0) {
                $storeLocation = [System.Security.Cryptography.X509Certificates.StoreLocation]::LocalMachine
            }
            else {
                $storeLocation = [System.Security.Cryptography.X509Certificates.StoreLocation]::CurrentUser
            }
        }
        #$store = [System.Security.Cryptography.X509Certificates.X509Store]::new([System.Security.Cryptography.X509Certificates.StoreName]::Root, "localmachine");
        $store = [System.Security.Cryptography.X509Certificates.X509Store]::new([System.Security.Cryptography.X509Certificates.StoreName]::Root,$storeLocation);
        $store.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::MaxAllowed);

        # Add to windows store or to .net store on linux
        foreach ($cert in $X509Certificate) {
            $store.Add($cert)
        }
        $store.Close();
    }
    if ($caCerts.IsPresent) {
        foreach ($cert in $X509Certificate) {
            $certString = ConvertTo-Base64Cert -X509Certificate $cert
            $filename = "$(Get-SafeAlias $cert.Subject).crt"
            $certFile = "/tmp/$filename"
            $certString | Add-Content $CertFile -ErrorAction Stop
            bash -c "sudo cp $CertFile /usr/local/share/ca-certificates/"
            Remove-Item $certFile -Force

        }
        bash -c "sudo update-ca-certificates"
    }
}


# Add to cacerts on linux
function ConvertTo-Base64Cert {
    param (

        [System.Security.Cryptography.X509Certificates.X509Certificate2]$X509Certificate
    )
    # convert x509 to base64 cert
    [String]$certString = $null
    $certString += "-----BEGIN CERTIFICATE-----`n"
    $byte = $X509Certificate.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Cert, "InsertLineBreaks")
    $certString += [System.Convert]::ToBase64String($byte, 'InsertLineBreaks')
    $certString += "`n-----END CERTIFICATE-----"
    $certString
}

function Get-SafeAlias {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory,
            ValueFromPipeline)]
        [String]
        $Alias
    )
    $pattern = "[^a-zA-Z0-9-_()\W]|`"|`'|=|,| |/"

    return ($Alias -replace $pattern, '')
}

# Import Certificates
$certs = Get-CertificatesFromUrl git.medavis.local
Import-X509Certificate -X509Certificate $certs -ChainOnly -CaCerts

$certs = Get-CertificatesFromUrl octo.medavis.com
Import-X509Certificate -X509Certificate $certs -WindowsOrDotNet


# profile
iex $((Invoke-WebRequest https://gist.githubusercontent.com/macces/e0087f756c7f77aad79f084fbdcc876e/raw/setup_profile.ps1).content);

<#
if ($chain.ChainElements.Certificate.Count -eq 1) {
    $certString = ConvertTo-Base64Cert -X509Certificate $chain.ChainElements.Certificate
    $filename = "$(Get-SafeAlias $chain.ChainElements.Certificate.Subject).crt"
    $certFile = "/tmp/$filename"
    $certString | Add-Content $CertFile -ErrorAction Stop
    bash -c "sudo cp $CertFile /usr/local/share/ca-certificates/"
    bash -c "sudo update-ca-certificates"
} else {
    for ($i = 1; $i -lt $chain.ChainElements.Certificate.Count; $i++) {
        $certString = ConvertTo-Base64Cert -X509Certificate $chain.ChainElements.Certificate[$i]
        $filename = "$(Get-SafeAlias $chain.ChainElements.Certificate[$i].Subject).crt"
        $certFile = "/tmp/$filename"
        $certString | Add-Content $CertFile -ErrorAction Stop
        bash -c "sudo cp $CertFile /usr/local/share/ca-certificates/"
    }
}

bash -c "sudo update-ca-certificates"

#>
