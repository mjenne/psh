Set-StrictMode -Version 2.0

Function Get-WMIMethodStaticMethodInput {
    [CmdletBinding()]

    param (
        [parameter(Mandatory=$false)]
        [string]
        $ComputerName = "localhost",

        [parameter(Mandatory=$false)]
        [string]
        $Namespace = "",

        [parameter(Mandatory=$true)]
        [string]
        $Class = "",

        [parameter(Mandatory=$true)]
        [string]
        $Method = ""
    )


    $c = Get-WmiObject -ComputerName $ComputerName -Namespace $Namespace -List -Authentication PacketPrivacy  | Where-Object {$_.Name -eq $Class}

    $c.psbase.GetMethodParameters($Method) 
}

Function Test-MTCWMIObject {
    [CmdletBinding()]

    param (
        [parameter(Mandatory=$true)]
        [string]
        $Name,

        [parameter(Mandatory=$true)]
        [string]
        $Class,

        [parameter(Mandatory=$true)]
        [string]
        $Namespace,

        [parameter(Mandatory=$true)]
        [string]
        $ComputerName
    )

    $TestCollection = @(Get-WmiObject -Class $class -Namespace $Namespace -ComputerName $ComputerName -Authentication PacketPrivacy | Where-Object {$_.Name -eq $Name} )

    if ($TestCollection.Length -eq 0) { return $false }
    else { return $true }
}

Function New-MTCRDGCAP {
    [CmdletBinding()]

    param (
        [parameter(Mandatory=$true)]
        [string]
        $Name,

        [parameter(Mandatory=$false)]
        [string]
        $ComputerGroupName = "",

        [parameter(Mandatory=$true)]
        [string]
        $UserGroupName = "",

        [parameter(Mandatory=$true)]
        [string]
        $ComputerName
    )


    $args = @(0,0,$ComputerGroupName,0,0,0,1,0,$Name,1,1,1,0,1,0,0,0,$UserGroupName)


    $a = @{
     ComputerName = $ComputerName;
     Namespace = "Root\CIMv2\TerminalServices";
     Name = "Create";
     ArgumentList = $args;
     Authentication = "PacketPrivacy";

     Class = "Win32_TSGatewayConnectionAuthorizationPolicy"
    }
    
    Invoke-WmiMethod @a
}

Function New-MTCRDGRAP {
    [CmdletBinding()]

    param (
        [parameter(Mandatory=$true)]
        [string]
        $Name,

        [parameter(Mandatory=$true)]
        [string]
        $Description,

        [parameter(Mandatory=$false)]
        [boolean]
        $Enabled = $true,

        [parameter(Mandatory=$false)]
        [string]
        $ResourceGroupName,

        [parameter(Mandatory=$true)]
        [string]
        $ResourceGroupType,

        [parameter(Mandatory=$false)]
        [string]
        $UserGroupNames,

        [parameter(Mandatory=$false)]
        [string]
        $ProtocolNames = "RDP",

        [parameter(Mandatory=$false)]
        [int]
        $PortNumbers = 3389,

        [parameter(Mandatory=$true)]
        [string]
        $ComputerName
    )


    $args = @($Description,$Enabled,$Name,$PortNumbers,$ProtocolNames,$ResourceGroupName,$ResourceGroupType,$UserGroupNames)

    $a = @{
     ComputerName = $ComputerName;
     Namespace = "Root\CIMv2\TerminalServices";
     Name = "Create";
     ArgumentList = $args;
     Authentication = "PacketPrivacy";

     Class = "Win32_TSGatewayResourceAuthorizationPolicy"
    }
    
    Invoke-WmiMethod @a
}

Function Get-HelperWMIObject {
    [CmdletBinding()]

    param (

        [parameter(Mandatory=$true)]
        [string]
        $ComputerName,

        [parameter(Mandatory=$true)]
        [string]
        $WMIClass,

        [parameter(Mandatory=$false)]
        [string]
        $Name = ""
    )

    Begin{}
    
    Process{
        $a = @{
         ComputerName = $ComputerName;
         Namespace = "Root\CIMv2\TerminalServices";
         Authentication = "PacketPrivacy";
         Class = $WMIClass;
         ErrorAction = "Stop"
        }

        if ($Name -ne "") 
            {          
            $a.Add("Filter","name=""$Name""") 
            }

    
        try { 
            # force results into collection
            $Result = @(Get-WmiObject @a)
            }

        catch [System.Runtime.InteropServices.COMException]
        {
            if ($_.FullyQualifiedErrorId.StartsWith("GetWMICOMException"))
            {
                #Write-Error "Error Connecting to RPC Server"
            }
            else { throw }
        }

        if ($Result -ne $null -and $Result.Length -ge 1) {
        
            Write-Verbose "Found WMI object $Result"

			#$Resources = @($RG.Resources.Split(";"))

            $Result

         
        } else {
            Write-Verbose "WMI Object not found"
        }


    }

    End{}

}

Function Get-MTCRDGResourceGroup {
    [CmdletBinding()]

    param (

        [parameter(Mandatory=$true)]
        [string]
        $ComputerName,

        [parameter(Mandatory=$false)]
        [string]
        $Name = ""
    )

    Get-HelperWMIObject -ComputerName $ComputerName -Name $Name -WMIClass "Win32_TSGatewayResourceGroup"

}

Function Get-MTCRDGCAP {
    [CmdletBinding()]

    param (

        [parameter(Mandatory=$true)]
        [string]
        $ComputerName,

        [parameter(Mandatory=$false)]
        [string]
        $Name = ""
    )

    Get-HelperWMIObject -ComputerName $ComputerName -Name $Name -WMIClass "Win32_TSGatewayConnectionAuthorizationPolicy"

}

Function Get-MTCRDGRAP {
    [CmdletBinding()]

    param (

        [parameter(Mandatory=$true)]
        [string]
        $ComputerName,

        [parameter(Mandatory=$false)]
        [string]
        $Name = ""
    )

    Get-HelperWMIObject -ComputerName $ComputerName -Name $Name -WMIClass "Win32_TSGatewayResourceAuthorizationPolicy"

}

Function Get-MTCRDGResourceGroupResources {
    [CmdletBinding()]

    param (

        [parameter(Mandatory=$true)]
        [string]
        $ComputerName,

        [parameter(Mandatory=$false)]
        [string]
        $Name = ""
    )

    $Result = @(Get-HelperWMIObject -ComputerName $ComputerName -Name $Name -WMIClass "Win32_TSGatewayResourceGroup")

    if ($null -ne $Result -and $Result.Length -ge 1 ) {

        $Resources = @($Result[0].Resources.Split(";"))

        $Resources
    }


}

Function New-MTCRDGResourceGroup {
    [CmdletBinding()]

    param (
        [parameter(Mandatory=$true)]
        [string]
        $Name,

        [parameter(Mandatory=$false)]
        [string]
        $Description = "",

        [parameter(Mandatory=$true)]
        [string]
        $Resources,

        [parameter(Mandatory=$true)]
        [string]
        $ComputerName
    )


    $args = @($Description,$Name,$Resources)

    $a = @{
     ComputerName = $ComputerName;
     Namespace = "Root\CIMv2\TerminalServices";
     Name = "Create";
     ArgumentList = $args;
     Authentication = "PacketPrivacy";

     Class = "Win32_TSGatewayResourceGroup"
    }
    
    Invoke-WmiMethod @a
}

Function Add-MTCRDGResource {
    [CmdletBinding(
        SupportsShouldProcess=$true,
        ConfirmImpact="Medium")]

    param (
        [parameter(Mandatory=$true)]
        [string]
        $ComputerName,
        
        [parameter(Mandatory=$true)]
        [string]
        $Name,

        [parameter(Mandatory=$true)]
        [string]
        $Resource
    )

    Begin{}
    
    Process{
        $a = @{
         ComputerName = $ComputerName;
         Namespace = "Root\CIMv2\TerminalServices";
         Authentication = "PacketPrivacy";
         Class = "Win32_TSGatewayResourceGroup";
         ErrorAction = "Stop";
         Filter = "name=""$Name"""
        }
    
        try { 
            $RG = Get-WmiObject @a  
            }

        catch [System.Runtime.InteropServices.COMException]
        {
            if ($_.FullyQualifiedErrorId.StartsWith("GetWMICOMException"))
            {
                #Write-Error "Error Connecting to RPC Server"
            }
            else { throw }
        }

        if ($RG -ne $null -and $RG.name -eq $Name) {
        
            Write-Verbose "Found WMI object $RG"

			if ($RG.Resources.Split(";") -contains $Resource) {
                Write-Verbose "Resource list for group $Name already contains $Resource"
            } else {
                Write-Verbose "Resource list for group $Name does not already contain $Resource and attempting to add"
            
                if ($PSCmdlet.ShouldProcess($Name, "Add $Resource")) { 
                    $result = $RG.AddResources($Resource) 
                    Write-Verbose "AddResources returned $($result.ReturnValue)"
                }
            }
        } else {
            Write-Verbose "WMI Object not found"
        }
    }

    End{}

}

Function Remove-MTCRDGResource {
    [CmdletBinding(
        SupportsShouldProcess=$true,
        ConfirmImpact="Medium")]

    param (
        [parameter(Mandatory=$true)]
        [string]
        $ComputerName,

        [parameter(Mandatory=$true)]
        [string]
        $Name,

        [parameter(Mandatory=$true)]
        [string]
        $Resource
    )

    Begin{}
    
    Process{

        $a = @{
         ComputerName = $ComputerName;
         Namespace = "Root\CIMv2\TerminalServices";
         Authentication = "PacketPrivacy";
         Class = "Win32_TSGatewayResourceGroup";
         ErrorAction = "Stop";
         Filter = "name=""$Name"""
        }
    
        try { 
            $RG = Get-WmiObject @a  
            }

        catch [System.Runtime.InteropServices.COMException]
        {
            if ($_.FullyQualifiedErrorId.StartsWith("GetWMICOMException"))
            {
                #Write-Error "Error Connecting to RPC Server"
            }
            else { throw }
        }


        if ($RG -ne $null -and $RG.name -eq $Name) {
    
            Write-Verbose "Found WMI object $RG"
        
            if ($RG.Resources.Split(";") -contains $Resource) {
                Write-Verbose "Resource list for group $Name contains $Resource"
                Write-Verbose "Attempting to remove"
                
                if ($PSCmdlet.ShouldProcess($Name,"Remove $Resource")) {
                    $result = $RG.RemoveResources($Resource)
                    Write-Verbose "RemoveResources returned $($result.ReturnValue)"
                }
            } else {
                Write-Verbose "Resource list for group $Name does not contain $Resource"
            }
        } else {
            Write-Verbose "WMI Object not found"
        }
    }

    End{}
}

Function New-MTCRDGRemoteLab {
    [CmdletBinding()]

    param (

        [parameter(Mandatory=$true)]
        [string]
        $ComputerName,

        [parameter(Mandatory=$true)]
        [string]
        $POCIdentifier,

        [parameter(Mandatory=$true)]
        [string]
        $UserGroups,

        [parameter(Mandatory=$false)]
        [string]
        $Resources="1.1.1.1",

        [parameter(Mandatory=$true)]
        [string]
        $Description
    )


    #test to see if required resource Group exists:
    
    
    
    if (!(Test-MTCWMIObject -Name $POCIdentifier -Class Win32_TSGatewayResourceGroup -Namespace "root\cimv2\terminalservices" -ComputerName $ComputerName))
        {
        $args = @{
            Name = $POCIdentifier.ToUpper();
            Description = "Auto-Provisioned: $Description";
            Resources = $Resources;
            ComputerName = $ComputerName;
            }

        $result = New-MTCRDGResourceGroup @args
        }



    if (!(Test-MTCWMIObject -Name $POCIdentifier -Class Win32_TSGatewayConnectionAuthorizationPolicy -Namespace "root\cimv2\terminalservices" -ComputerName $ComputerName))
        {
        $args = @{
            Name = $POCIdentifier.ToUpper();
            ComputerGroupName = "";
            UserGroupName = $UserGroups;
            ComputerName = $ComputerName;
            }

        $result = New-MTCRDGCAP @args
        }

    if (!(Test-MTCWMIObject -Name $POCIdentifier -Class Win32_TSGatewayResourceAuthorizationPolicy -Namespace "root\cimv2\terminalservices" -ComputerName $ComputerName))
        {
        $args = @{
            Name = $POCIdentifier.ToUpper();
            Description = "Auto-Provisioned: $Description";
            ResourceGroupName = $POCIdentifier.ToUpper();
            ResourceGroupType = "RG";
            ComputerName = $ComputerName;
            UserGroupNames = $UserGroups
            }

        $result = New-MTCRDGRAP @args
        }
}

Export-ModuleMember *MTCRDG*


# SIG # Begin signature block
# MIIJ5gYJKoZIhvcNAQcCoIIJ1zCCCdMCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUEb73Xy6v/SQc+9hd3PtO340j
# frmgggcuMIIHKjCCBRKgAwIBAgITFQAAAc1t+KEkpNmzaAAAAAABzTANBgkqhkiG
# 9w0BAQUFADBpMRMwEQYKCZImiZPyLGQBGRYDQ09NMRUwEwYKCZImiZPyLGQBGRYF
# TVRDV1cxFzAVBgoJkiaJk/IsZAEZFgdUT1JPTlRPMSIwIAYDVQQDExlUT1JPTlRP
# IE1UQyBFTlRFUlBSSVNFIENBMB4XDTE0MTExMjIzMjIyOVoXDTE1MTExMjIzMjIy
# OVowbjETMBEGCgmSJomT8ixkARkWA0NPTTEVMBMGCgmSJomT8ixkARkWBU1UQ1dX
# MRcwFQYKCZImiZPyLGQBGRYHVE9ST05UTzESMBAGA1UECxMJTVRDIFN0YWZmMRMw
# EQYDVQQDEwpNaWtlIEplbm5lMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKC
# AQEAy4PzDrdf3jaJ5vStuBzkgjtonwj8qSGTlksmXlqEKFvgNCDugmWfGvoMAff4
# oxilU5eVBn1P0Aussmi0J5oUGLh2Ijakop5m/x87jr8Rf62JAUt1wf8SrwydVxxc
# wV6OK7IjisiDVHiHgdkpHR0RL5wUcwN4qu3Tvq11ctW4hcNzGWUhB0EIRd8QeW4R
# At/5DBny5d5W/zwawYS1JJYFRp1QgywNnVCMPtnULhZ9jOuchhVML+Kl6gygLlU9
# Hi5V5485cgG0AJA72l6QGje/gvaF7QaDfjxp/42IOd0inKDcQ/3+gm8qArfNfpFA
# NYhbRU+HfJBri+Hm6BnJxxFMxwIDAQABo4ICxDCCAsAwPgYJKwYBBAGCNxUHBDEw
# LwYnKwYBBAGCNxUIgaX2a4Ss6xqBxZkBhu/SZoO+kwiBb4XvhjuHj6kqAgFkAgEC
# MBMGA1UdJQQMMAoGCCsGAQUFBwMDMA4GA1UdDwEB/wQEAwIHgDAbBgkrBgEEAYI3
# FQoEDjAMMAoGCCsGAQUFBwMDMB0GA1UdDgQWBBSgLFwj0Ocz0gps/YKQcc4UvntI
# /zAfBgNVHSMEGDAWgBRK2uPPffOE8COJ3JxIdTvN7DEDtTCB6QYDVR0fBIHhMIHe
# MIHboIHYoIHVhoHSbGRhcDovLy9DTj1UT1JPTlRPJTIwTVRDJTIwRU5URVJQUklT
# RSUyMENBLENOPVRPUi1QLUNBMDEsQ049Q0RQLENOPVB1YmxpYyUyMEtleSUyMFNl
# cnZpY2VzLENOPVNlcnZpY2VzLENOPUNvbmZpZ3VyYXRpb24sREM9VE9ST05UTyxE
# Qz1NVENXVyxEQz1DT00/Y2VydGlmaWNhdGVSZXZvY2F0aW9uTGlzdD9iYXNlP29i
# amVjdENsYXNzPWNSTERpc3RyaWJ1dGlvblBvaW50MIHaBggrBgEFBQcBAQSBzTCB
# yjCBxwYIKwYBBQUHMAKGgbpsZGFwOi8vL0NOPVRPUk9OVE8lMjBNVEMlMjBFTlRF
# UlBSSVNFJTIwQ0EsQ049QUlBLENOPVB1YmxpYyUyMEtleSUyMFNlcnZpY2VzLENO
# PVNlcnZpY2VzLENOPUNvbmZpZ3VyYXRpb24sREM9VE9ST05UTyxEQz1NVENXVyxE
# Qz1DT00/Y0FDZXJ0aWZpY2F0ZT9iYXNlP29iamVjdENsYXNzPWNlcnRpZmljYXRp
# b25BdXRob3JpdHkwMwYDVR0RBCwwKqAoBgorBgEEAYI3FAIDoBoMGG1qZW5uZUBU
# T1JPTlRPLk1UQ1dXLkNPTTANBgkqhkiG9w0BAQUFAAOCAgEAMNShnmGLPbeC5UXf
# tFGYqdlqnBPpGORo15eZQZdhRCHGNdO8lA4z5IA8Dj5Z3pV34DLx1Q97wk9cyeEe
# luqFcHQl5qc6qwvkRs4KjBQwEGdV3LkwX1ZZT6vIQCqQnOYGv8HdBCA57gnzjrvM
# qKG+/ilhG/RxLWSUF6nsP1S11GjeajFkGTjDUz9c2QBrVK1+zVxpkCjdXLUe7Pjr
# E62ong8iIGXCL2Qo4JYkfkVNtHKI+iu3H9nULUV3nWsTLNURHEb89y9efd76YFDN
# 0bfPIEB6AdEvBoV00Usr7VtfUGzCAS6+CTYLLp87aAma7c9Q2a3zQA3LSp56vwtV
# F6K8+UuOLb4dQlG4LlHJPSwnXWW8AS9gd8/fpjnyK6XYOjlY8Dkw3ZegdHcJ8s3r
# J2RYdpw/6BZbj8s0xYDJ7cFdTcG90d1Bm12cRYOyz0xkPZGzp1gSXOpkUjIL7ngj
# DyLa/RLnbeTVDhNKKAA4uYudg2GVDETPo7fxQJ2RQZqxOZErTMGjIIeJ0bJtVacX
# M7hwrbrw51XCd3lnEyXTCGf6W/fpmvcm9Twt5vBllXEK7xBHJYpqNz8RvNyOyqPh
# nMMIPcelNIXyQdQ6nFaV88OOUvOLxy8AmtkMf2fAdHHLvSCmoVjvjog+0hSDSVXQ
# 9CU/E05UYCOIUPsAUMWaPhu1LswxggIiMIICHgIBATCBgDBpMRMwEQYKCZImiZPy
# LGQBGRYDQ09NMRUwEwYKCZImiZPyLGQBGRYFTVRDV1cxFzAVBgoJkiaJk/IsZAEZ
# FgdUT1JPTlRPMSIwIAYDVQQDExlUT1JPTlRPIE1UQyBFTlRFUlBSSVNFIENBAhMV
# AAABzW34oSSk2bNoAAAAAAHNMAkGBSsOAwIaBQCgeDAYBgorBgEEAYI3AgEMMQow
# CKACgAChAoAAMBkGCSqGSIb3DQEJAzEMBgorBgEEAYI3AgEEMBwGCisGAQQBgjcC
# AQsxDjAMBgorBgEEAYI3AgEVMCMGCSqGSIb3DQEJBDEWBBRgffUQqGeJAp7mBdN+
# ROPqL+ncjTANBgkqhkiG9w0BAQEFAASCAQB59Zd1x/9SlYswaP5QHdwXSNfxs5DW
# ZUV3xpVWHLeAK4At3lD52gYTiq+5oGr1/NasJbPULBCeTXAJhV12dBJBOS9Y7cEy
# KGQP6uNCQYO9+RG47AXsuupCi4e2byy3vVKG3fManNkEa1hrPnO7XwIEsYLsAfUQ
# cyw3lBwbwrhDRbkAT9qaNFlXSbWcscu7VQX8xd7PnhZRD6OMz75ypq6W2jcuMya5
# 8g/dbGfyi6/bXrnYeLiznRk6s4v8eLC0V3l8aAG+Sbyf5Rg98DPen8ejDk26DX0f
# 3S2JVfgGiFFe4WAL0ir7H3Eopa5eatmEU8BvzOhn0rIjnm5u6JKnTnyH
# SIG # End signature block
