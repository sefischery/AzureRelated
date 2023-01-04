# This script is intended to simply start a <SPECIFIC VM>, not an input paramter
# this is imply due to the fact that this is the same thing that will be done again and again.


$PowerAction = $args[0] # on or off
# Check if theaction is valid
if ($PowerAction.ToUpper() -ne 'ON' -and $PowerAction.ToUpper() -ne 'OFF') {
    Write-Output 'Invalid Input. Valid values are "On" or "Off".'
    exit
}

# Sign in and retrieve all the subscrpitions that the user has access to

$subscriptionName = "sefischer_sub"
$VM_names = "DC1","sf-VM2server","VM1" #add more here if you have them in the lab.
$resourcegrp = "sf-LAB"

Connect-AzAccount
$subscriptions = Get-AzSubscription -ErrorAction SilentlyContinue

# use this if you have the direct SUB ID.
# Set-AzContext -SubscriptionId "<SOME-SUB-ID>" 

foreach($subscription in $subscriptions){
    if ($subscription.Name -eq $subscriptionName){
        Write-Host "Found subscription ID: $($subscription.Id)"
        Set-AzContext -SubscriptionId $subscription.Id #setting context
    }
}


# loop the VM's and check the state
if ($PowerAction -eq 'On') {
    foreach($VM_name in $VM_names){
        $virtualmachine = Get-AzVM -ResourceGroupName $resourcegrp -Name $VM_name

        # check if the VM is running (it shouldn't be but okay)
        if ($virtualmachine.PowerState -eq 'Running'){
            Write-Output "Virtual Machine '$VM_name' is already running"
        }
        else {
            # boot it
            Start-AzVM -ResourceGroupName $resourcegrp -Name $VM_name -NoWait #with nowait it returns immmediatly before the operation is completed. 
            Write-Output "Virtual machine '$VM_name' started."
        }
    }

    $publicIP_raw = (Invoke-WebRequest -UseBasicParsing -Uri "https://www.showmyip.com/" -Method Get).Content
    $publicIP_raw -match '(?<=<h2 id="ipv4">)(.*)(?=<\/h2>)'
    $publicIP = $Matches[0]

    $rdpPORT = 3389

    Write-Output "Your public IP address is: $publicIP"

    # can't get it to work for some reason with the variables $ so I suspect something is up when not doing it hardcoded or I'm not doing it right rn,works atm with hardcoded string. 

    $JitPolicyVm1 = (@{
        id="/subscriptions/<<<<SUBSCRIPTIONID>>>>>>>/resourceGroups/sf-LAB/providers/Microsoft.Compute/virtualMachines/DC1";
        ports=(@{
        number=3389;
        endTimeUtc="2023-01-04T13:00:00.3658798Z";
        allowedSourceAddressPrefix=@("$publicIP")})})


    $JitPolicyArr=@($JitPolicyVm1)

    Start-AzJitNetworkAccessPolicy -ResourceId "/subscriptions/<<<<SUBSCRIPTIONID>>>>>>>/resourceGroups/sf-LAB/providers/Microsoft.Security/locations/northeurope/jitNetworkAccessPolicies/default" -VirtualMachine $JitPolicyArr
}
else{
    foreach($VM_name in $VM_names){
        $virtualmachine = Get-AzVM -ResourceGroupName $resourcegrp -Name $VM_name

        # check if the VM is already stopped (it shouldn't be but okay)
        if ($virtualmachine.PowerState -eq 'Stopped'){
            Write-Output "Virtual Machine '$VM_name' is already offline"
        }
        else {
            # kill it
            Stop-AzVM -ResourceGroupName $resourcegrp -Name $VM_name -Force -NoWait #with nowait it returns immmediatly before the operation is completed. 
            Write-Output "Virtual machine '$VM_name' stopped."
        }
    }

    Write-Output "Done killing VMs - quitting."
}

