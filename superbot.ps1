param ($Message, $Bot)

#$State = $State | select Counter
#$State.Counter += 1
#Write-Host "Counter = $($State.Counter)"

switch ($Message.Command)
{
    "ping" { write-host "haha!" }
    default
    {
        #Write-Host "CMD $Message"
        return
    }
}

#Write-Host $Command