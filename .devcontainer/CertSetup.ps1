"starting Script"

$ca = @'
-----BEGIN CERTIFICATE-----
MIIFCzCCAvOgAwIBAgIQSi6PBWIaHZVJ9Fgpol7HKjANBgkqhkiG9w0BAQsFADAY
MRYwFAYDVQQDEw1tZWRhdmlzUm9vdENBMB4XDTE3MDgyMjA2MjcwNloXDTM3MDgy
MjA2MzcwMVowGDEWMBQGA1UEAxMNbWVkYXZpc1Jvb3RDQTCCAiIwDQYJKoZIhvcN
AQEBBQADggIPADCCAgoCggIBALKDnsK2GjDMfqFh7ma8lnvhJoNRFRIL0IBpRtMJ
dQ3Y7JA9nN1H9KA8xb40voHahD/2el5aoaFskZgT4sE5vVVyr0nTdW1LFTuH7SOh
AKXwO0tN0JKXxkFLLUZFRrK7hmoiv29gY3TbVHJbthT3Gjqqa8OkNwS0U8SVV3tt
no50MNYPZ8ZnObRm3flcd42XAmcXAlO6QagelRQALQ4CF08V3JP7tG1lDX/rOvWi
c4cf9620VYG29q4GDFgLC29gPLWd6J1q2lEzVbwykSrL4uLYetchug3cMuf35zqU
7LEYo+6GYfaMYc6ZKhfL+9sSPYhHdcE/wVUhbxQnI2d9aEShTnrrbpkPwyBMe69k
TjLQ0FZsraDMEKKwftLFyNURReXNdNtlm5s9s2jTslQIZvIlfS2lOMLh/eMigKzb
pzj5BPicwMnDacBbV1nuxfI2tWuL/LU+KgnGfsdSNYc77Gk4vKeXmg0+KL0TXAnK
E6Up2s7slFu+zeo2WpweUE2WhRPGyz6Uc4HX81rwfaRBp1LCSlAN9D2/aJbEY+Jh
MxvPZ0+fsUTuOhYzjcPiuak9BmcxQZ0goCuoJHCKcO9G1XbaGl/gz3SUwWLIMVcK
QJO6AAobuORcfSZHdtKqUcwnXcUm5pFm+etf0BOVUkQ7+icOj5s8KT6MZv9GXqz2
BmFHAgMBAAGjUTBPMAsGA1UdDwQEAwIBhjAPBgNVHRMBAf8EBTADAQH/MB0GA1Ud
DgQWBBT8jbNPiuc/W/3VcyBwbnrru4NhkzAQBgkrBgEEAYI3FQEEAwIBADANBgkq
hkiG9w0BAQsFAAOCAgEAG6R2Q7Xw8DofqvyRA4/65M7oLf3tKOK5wMOYN2782Ql7
qEOFV18itu8g2gS1meX9Y28AERVsJIBbOObqMwK6C9mrpyPaM9pgQWT8x3t4URyZ
nsI13eJYhQHlxR/SQE7cdOhhtOvtYYrjDtKadtEJ0/PWRyd6tR13HtnYi7OGQ7r+
wnh9NLfKGjMzv7nyGBxnycfTxBEZ/iJH3xxcg9RzioTs3KkE56JfDp1x4jy5czLW
5TujFmvCGJXC2pCRa38Zg/gxHapRyOQT9SQ5qACv08wjv88tzijYNRNrz3V752rw
/CRR+HGLSJSIE6P8i/7ZHeXZeowG8aj9yw86XoP8KYcjMqYThIiN08D6j+t+bdvZ
IBTyfNCS2sAOCpQfpO3M4TMGVoPq8Ah+WgxSvxjKgTIOPh5xa6fTDXCKwT65fSL2
AuGH1MNb1zb4OfYTVRilf5qZs+QLJBZ0SAbj2o7GTs9TsCGDLjrx7dcxNQosGPsz
K0tE6RergtCVHzAxTAawvbtmLx7eikJDaUWnXAiMUm8ea+Ve4Lughq60+vfD02ou
Pl1HSknOvWDiMy+mtuudEQxIyqtvL9oap2yj8BgLZIkz4Xc2hU/nwDzW+yN+ofPy
aBWxi9tq4Pd5I+1NIhe+LtHPB8e8eD1+6eMhTSvn2QK4i3MKl/YK9O9hErmVENY=
-----END CERTIFICATE-----

'@
$inter = @'
-----BEGIN CERTIFICATE-----
MIIHljCCBX6gAwIBAgITEAAAAALWFV5sww2qRgAAAAAAAjANBgkqhkiG9w0BAQsF
ADAYMRYwFAYDVQQDEw1tZWRhdmlzUm9vdENBMB4XDTE3MDgyMjE0MTAzOFoXDTI3
MDgyMjE0MjAzOFowUDEVMBMGCgmSJomT8ixkARkWBWxvY2FsMRcwFQYKCZImiZPy
LGQBGRYHbWVkYXZpczEeMBwGA1UEAxMVbWVkYXZpc0ludGVybWVkaWF0ZUNBMIIC
IjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAm243wKTLPT4i0+oN2o6BwrG9
M9/daLywJUjKf75mLDyIp3lP4OSISOOoW1aMEBu4T9coTiqB6xrQV1Ow66kaIh7C
iovh+ZbM3g/lBLspbUAMYAxN2kYDY74WPzcTxaKISXKF6+8XIsL6Hq3xzg+2dEmV
L0Wshhq3DlA4GGz1MhCke2uQO9Nmj41G7TROYEvqEHSE9EWJ36+py1BU3JHl/qi3
NGy5vB21tjI2USta+26kuS8DqIHqIOiKV9J0Y2F5HtKOTFpoLCghzlgZS6HrDqZ8
aIsKQVBzEeEZcvzkht445OXJTnU1O9umu/JbmxLb0FPOwO7dx31EdRvv5VaiZtLK
3dHdBjE13oi2vRs0hmgI77WqfEJ4G3Zm4QhEnBq/UFPiZIwSON2MB7Ptry8YIPgH
JNtBZM81pOnZF/A0u2fBzSvt0HQrIMUr8aS++D11k+ZaLoqkOAT/IQjaSogqd0AL
vuH9Z2UF7alPaCczjWIZuRBCcFDxnYqgH4EFAGM/XqMAUAHqV8cRXmiL6TDN7g9Q
PpxYgoT2l8+VUDaLWD7/oSPo26cvYAjshbMAZcgAcFoIQtEBAfQ0lOWrI1Nvf50a
TF1wWjtYBRF2/WhA0+D5Q7hfHRxrh8RcnQDUAy8wvW0eV7CdMllRLN9/OiyjqMDb
3QqFDFMDFtvBScDbFfkCAwEAAaOCAp8wggKbMBAGCSsGAQQBgjcVAQQDAgEAMB0G
A1UdDgQWBBR8DMs5qOY5/alGHzK1ynhp8gvsGjAZBgkrBgEEAYI3FAIEDB4KAFMA
dQBiAEMAQTALBgNVHQ8EBAMCAYYwDwYDVR0TAQH/BAUwAwEB/zAfBgNVHSMEGDAW
gBT8jbNPiuc/W/3VcyBwbnrru4NhkzCCAQAGA1UdHwSB+DCB9TCB8qCB76CB7IaB
t2xkYXA6Ly8vQ049bWVkYXZpc1Jvb3RDQSxDTj1ERVNFQ0EwMSxDTj1DRFAsQ049
UHVibGljJTIwS2V5JTIwU2VydmljZXMsQ049U2VydmljZXMsQ049Q29uZmlndXJh
dGlvbixEQz1tZWRhdmlzLERDPWxvY2FsP2NlcnRpZmljYXRlUmV2b2NhdGlvbkxp
c3Q/YmFzZT9vYmplY3RDbGFzcz1jUkxEaXN0cmlidXRpb25Qb2ludIYwaHR0cDov
L3BraWNybC5tZWRhdmlzLmNvbS9jZXJ0L21lZGF2aXNSb290Q0EuY3JsMIIBCAYI
KwYBBQUHAQEEgfswgfgwga4GCCsGAQUFBzAChoGhbGRhcDovLy9DTj1tZWRhdmlz
Um9vdENBLENOPUFJQSxDTj1QdWJsaWMlMjBLZXklMjBTZXJ2aWNlcyxDTj1TZXJ2
aWNlcyxDTj1Db25maWd1cmF0aW9uLERDPW1lZGF2aXMsREM9bG9jYWw/Y0FDZXJ0
aWZpY2F0ZT9iYXNlP29iamVjdENsYXNzPWNlcnRpZmljYXRpb25BdXRob3JpdHkw
RQYIKwYBBQUHMAKGOWh0dHA6Ly9wa2lhaWEubWVkYXZpcy5jb20vY2VydC9ERVNF
Q0EwMV9tZWRhdmlzUm9vdENBLmNydDANBgkqhkiG9w0BAQsFAAOCAgEABXjxvy4e
7TAuThySqxnuj91tC+cCa+umIAIoxGgngV90+rx/UHSGi05U9uRjIqwcMcvL1jfs
czG0I10mcqZLWoHB62SqA5CI7UrO+jLEJhT/CxeD1QxsXRW7CO4xM+sc0tIlCVcg
pFmLh1IwKYkgrz2ACfl+C2fN10rlcM6ixbu3CanSnFdBRaUJBtMSPiYU/mCXhxlK
giROuK1YojsjIHdBhuxFd0Xc3MO4Tco3U3tBfODoKVC4LHmot+XDOEvGRp0XnbZl
zlOk0UjwxLnXpgh64fBdiCh+3jFonmNcm/PLH/CVncf1cfJZezrp/MDRBjEjOPKM
NGY1w6X+ftTyqkXgAYOCgXzLFsw2tZidzQflzU1Q2ZPtMHJ0y6F+/PrUJDe+7Irv
0KD58AUxbJ/hnT/F3nqY1lDOOpPlCXed/rqV7UiZg03qmJjJFy8VevtD73tJkaqB
ZuaIUc/Jo8hdG39Jr3tIKknLobTKXs0wVbKvzMyqESukj0TW7ah+h0/Tk+qldqM3
bkgSB6ioHSkZQH44y8W3dyrrVqVS9vqUIi8M9kKfFtByuZFCSDiuiD3K5EW6Y9Wo
J8EjF18vyKmcR63RntqjuC3zmm3kbWc2fOwG1HBC0CgyZFraJH5Cbe3G7/6W3NJh
la3IjnrG/ZQy22wliadOqSyVovbzomRj2jk=
-----END CERTIFICATE-----
'@
$certname = "ca.crt"
$certFile = "/tmp/$certname"
$ca | Add-Content $CertFile -ErrorAction Stop

# the next steps have to be done with sudo
bash -c "sudo cp $CertFile /usr/local/share/ca-certificates/"

$certname = "inter.crt"
$certFile = "/tmp/$certname"
$inter | Add-Content $CertFile -ErrorAction Stop
# the next steps have to be done with sudo
bash -c "sudo cp $CertFile /usr/local/share/ca-certificates/"

#octo Cert
$octoCert = @'
-----BEGIN CERTIFICATE-----
MIICuDCCAaCgAwIBAgIIR07F5txGckEwDQYJKoZIhvcNAQELBQAwGzEZMBcGA1UEAwwQb2N0by5tZWRhdmlzLmNvbTAgFw0yMDEwMTkwMDAwMDBaGA8yMTIwMTAyMDAwMDAwMFowGzEZMBcGA1UEAwwQb2N0by5tZWRhdmlzLmNvbTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAOfzdsfwdpZ+3kWbnYgXJMTfDFw5Gry7Rxf2oAKKiQjgxp5vGFpasUpf9UMUA8++q1jb4MHg/VgEsQ+ROve566+py/tq2uTBviPAQnFzjkK35YwyhfW6OTvbtJIdVQc5M6FHdbypbgP3/uQwQV1ixbchxCR00z+DgSTZc6g4xMiXlmaD7hj9qGlVNxgAqu12MaC6eV9YP+qHOw4ka1WsZjndwgD9WEu0z1p8DgIHvRDc4nz+xqhtwxepSoA9g5TweHI1A7pqrl6WVJO31JdGBI3pJwEAVIO9d0b2t50VK5WwMjpHO1yi3ymnEc4chvGwgDD03S8qn+HuACvyKzFW+B0CAwEAATANBgkqhkiG9w0BAQsFAAOCAQEAIEesILTt/+AG5PVefCtLWGW/Ka6NgrIBttNh+6lUwLtAT+v4Hqd3Y7luuvwFT4UnewkfsEZ8Y1vMyP6AqhqKmWrOGdHw9zorFvdvLEeVMHUPuD33Bw+nJIg2asigSaQ+W2dusa/DS7vdVa0BfdtdjlAnes8gkgOH6Vw4G3VLn1s5qPzQG1lHYhK/y6bQGF53Ryjl6+yfxsdNsrtR8qyiwKbBkN7Pp9QGRoVujwZyE9VxKVVtocYF0NqtaHL1Pf6kh0iXWPxxbHDVDDevhY4HXkMOD9YvdoKP0HmE9nq7Ky8eCQ8J73jxcPYkp936XLs3VRpP6fVeMYUVmsid+N0YMQ==
-----END CERTIFICATE-----
'@
<#
$certname = "octoCert.crt"
$certFile = "/tmp/$certname"
$octoCert  | Add-Content $CertFile -ErrorAction Stop
bash -c "sudo cp $CertFile /usr/local/share/ca-certificates/"
bash -c "sudo update-ca-certificates"
#>
# profile
iex $((Invoke-WebRequest https://gist.githubusercontent.com/lindnerbrewery/e0087f756c7f77aad79f084fbdcc876e/raw/setup_profile.ps1).content);



<#
#this will add cert to ca certs (might not work with git windows settings)
$cert = Get-RemoteSSLCertificate "git.medavis.local" -Verbose
$certname = "git.medavis.local.crt"

$certFile = "$pwd/$certname"
"-----BEGIN CERTIFICATE-----" | Add-Content $CertFile -ErrorAction Stop
[System.Convert]::ToBase64String($Cert.Export('cert', "InsertLineBreaks")) | Add-Content $CertFile
"-----END CERTIFICATE-----" | Add-Content $CertFile

# the next steps have to be done with sudo
bash -c "sudo cp $CertFile /usr/local/share/ca-certificates/"
bash -c "sudo update-ca-certificates"

# add environment variable to ignore ssl altogether
# $env:GIT_SSL_NO_VERIFY = $true

# ToDo:  try this next time
# git config http.sslCAinfo "/etc/ssl/certs/ca-certificates.crt"
#>
