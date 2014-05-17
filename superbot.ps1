param ($Message, $Bot)

$Bot.State.Counter += 1
Write-Host "Counter = $($Bot.State.Counter)"
#throw "wtf"

switch -regex ($Message.Text)
{
    "lol"
    {
        "haha :)"
        $bot.TimerInterval = 5000
    }
    "diebot" { "/quit :cya guys!" }
}

switch ($Message.Command)
{
    "BOT_STATIC_INIT"
    {
        if ($bot.State.DieImmediately) { throw "shit!" }
    }
    "join" { "/msg $($Message.Arguments[0]) /me says hi to everyone on $($Message.Arguments[0])"}
    "ping" { "pong! $(Get-Date)" }
    "BOT_TICK" { "haha LOCALS RULE -- $(Get-Date)" }
    default
    {
        #Write-Host "CMD $Message"
        return
    }
}

#Write-Host $Command