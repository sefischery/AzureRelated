# This script is intended to simply start a <SPECIFIC VM>, not an input paramter
# this is imply due to the fact that this is the same thing that will be done again and again.


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
        Write-Host "Found subscription ID :$($subscription.Id)"
        Set-AzContext -SubscriptionId $subscription.Id #setting context
    }
}


# loop the VM's and check the state

foreach($VM_name in $VM_names){
    $virtualmachine = Get-AzVM -ResourceGroupName $resourcegrp -Name $VM_name

    # check if the VM is running (it shouldn't be but okay)
    if ($virtualmachine.PowerState -eq 'Runnning'){
        Write-Output "Virtual Machine '$VM_name' is already running"
    }
    else {
        # boot it
        Start-AzVM -ResourceGroupName $resourcegrp -Name $VM_name -NoWait #with nowait it returns immmediatly before the operation is completed. 
        Write-Output "Virtual machine '$VM_name' started."
    }
}

