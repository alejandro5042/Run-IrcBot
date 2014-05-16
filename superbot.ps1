param ($Message, $Command, [ref]$State, [switch]$awesome)

#$State = $State | select Counter
#$State.Counter += 1
#Write-Host "Counter = $($State.Counter)"

switch ($command)
{
    "ping" { write-host "haha!" }
    default
    {
        #Write-Host "CMD $Message"
        return
    }
}

#Write-Host $Command