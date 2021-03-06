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


    $a = @{
        ComputerName = $ComputerName;
        Namespace = $Namespace;
        Authentication = "PacketPrivacy";
        Class = $Class;
        ErrorAction = "Stop"
        Filter = "name=""$Name""" 
    }


    $TestCollection = @(Get-WmiObject @a)

    if ($TestCollection.Length -eq 0) { return $false }
    else { return $true }
}

Function New-MTCRDGConnectionAuthorizationPolicy {
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

Function New-MTCRDGResourceAuthorizationPolicy {
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

        [parameter(Mandatory=$true)]
        [string]
        $Namespace = "Root\CIMv2\TerminalServices",

        [parameter(Mandatory=$false)]
        [string]
        $Name = ""

    )

    Begin{}
    
    Process{
        $a = @{
         ComputerName = $ComputerName;
         Namespace = $Namespace;
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

    Get-HelperWMIObject -ComputerName $ComputerName -Name $Name -WMIClass "Win32_TSGatewayResourceGroup" -Namespace "Root\CIMv2\TerminalServices"

}

Function Get-MTCRDGConnectionAuthorizationPolicy {
    [CmdletBinding()]

    param (

        [parameter(Mandatory=$true)]
        [string]
        $ComputerName,

        [parameter(Mandatory=$false)]
        [string]
        $Name = ""
    )

    Get-HelperWMIObject -ComputerName $ComputerName -Name $Name -WMIClass "Win32_TSGatewayConnectionAuthorizationPolicy" -Namespace "Root\CIMv2\TerminalServices"

}

Function Get-MTCRDGResourceAuthorizationPolicy {
    [CmdletBinding()]

    param (

        [parameter(Mandatory=$true)]
        [string]
        $ComputerName,

        [parameter(Mandatory=$false)]
        [string]
        $Name = ""
    )

    Get-HelperWMIObject -ComputerName $ComputerName -Name $Name -WMIClass "Win32_TSGatewayResourceAuthorizationPolicy" -Namespace "Root\CIMv2\TerminalServices"

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

    $Result = @(Get-HelperWMIObject -ComputerName $ComputerName -Name $Name -WMIClass "Win32_TSGatewayResourceGroup" -Namespace "Root\CIMv2\TerminalServices" )

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
        $Name,

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
    
    
    
    if (!(Test-MTCWMIObject -Name $Name -Class Win32_TSGatewayResourceGroup -Namespace "root\cimv2\terminalservices" -ComputerName $ComputerName))
        {
        $args = @{
            Name = $Name.ToUpper();
            Description = "Auto-Provisioned: $Description";
            Resources = $Resources;
            ComputerName = $ComputerName;
            }

        $result = New-MTCRDGResourceGroup @args
        }



    if (!(Test-MTCWMIObject -Name $Name -Class Win32_TSGatewayConnectionAuthorizationPolicy -Namespace "root\cimv2\terminalservices" -ComputerName $ComputerName))
        {
        $args = @{
            Name = $Name.ToUpper();
            ComputerGroupName = "";
            UserGroupName = $UserGroups;
            ComputerName = $ComputerName;
            }

        $result = New-MTCRDGConnectionAuthorizationPolicy @args
        }

    if (!(Test-MTCWMIObject -Name $Name -Class Win32_TSGatewayResourceAuthorizationPolicy -Namespace "root\cimv2\terminalservices" -ComputerName $ComputerName))
        {
        $args = @{
            Name = $Name.ToUpper();
            Description = "Auto-Provisioned: $Description";
            ResourceGroupName = $Name.ToUpper();
            ResourceGroupType = "RG";
            ComputerName = $ComputerName;
            UserGroupNames = $UserGroups
            }

        $result = New-MTCRDGResourceAuthorizationPolicy @args
        }
}

Export-ModuleMember *MTCRDG*
#comment made for source control testing
