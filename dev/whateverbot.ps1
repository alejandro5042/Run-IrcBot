param ($Message, $Bot)

switch ($Message.Command)
{
    "join"
    {
        if ($Message.SenderNickname -ne $Bot.Nickname)
        {
            "hey there $($Message.SenderNickname), what's up?"
        }
    }
}

if ($Bot.CurrentError)
{
    $Bot.CurrentError.GetType()
}

switch ($Message.Text)
{
    "throw"
    {
        throw "awesome"
    }
    default
    {
        $Message.Text
        $Message.Text
    }
}