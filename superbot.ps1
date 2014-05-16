param ($Message, $Bot)

$Bot.State.Counter += 1
Write-Host "Counter = $($Bot.State.Counter)"
#throw "wtf"

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