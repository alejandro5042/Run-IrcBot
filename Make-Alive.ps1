# TODO: Add license
# TODO: Need /__keepalive

[CmdLetBinding()]
param
(
    [Parameter(Mandatory = $true)]
    $BotScript,
    
    [Parameter(Mandatory = $true)]
    [string]
    $Server,
    
    [string]
    $Channel,
    
    $State = @{}
)

# TODO: Hook this up as the default bot.... maybe?
function MonitorBot ($message, $bot)
{
    if ($message.Text)
    {
        $message.Text
    }
}

function InstinctBot ($message, $bot)
{
    switch ($message.Command)
    {
        "__begin"
        {
            "/nick $($bot.UserName)"
            "/user $($bot.UserName) localhost $($bot.ServerName) ps-ircbot"
            break
        }
        "__end"
        {
            Write-Host "Bye!"
            break
        }
        "ping"
        {
            "/pong $($message.ArgumentString)"
            break
        }
        "433" # Nickname already in use.
        {
            $newNick = $message.Arguments[1] + "_"
            "/nick $newNick"
            break
        }
        "323"
        {
            #"/quit haha"
            break
        }
        "376"
        {
            "/list"
            break
        }
        "error"
        {
            exit
        }
        default
        {
            # write-host $command $args
            break
        }
    }
}

filter Parse-OutgoingLine ($message, $bot)
{
    switch -regex ($_)
    {
        '^/me\s+(.*)' {
            "$([char]1)ACTION $($Matches[1])$([char]1)"
            break
        }
        '^/' {
            $_.Substring(1)
            break
        }
        default {
            $_
            break
        }
    }
}

filter Write-Irc ($message, $bot)
{
    ([string]$_) -split '\n' |
        Parse-OutgoingLine $message $bot |
        foreach {
            Write-Verbose "<< $_"
            $bot.Writer.WriteLine($_)
            $bot.Writer.Flush()
            sleep -Milliseconds $bot.InteractiveDelay
        }
}

filter Parse-IncomingLine ($bot)
{
    switch -regex ($_)
    {
        "^(?::([^\s]*)\s+)?([^\s]+)(?:\s*(.*))?" {
            Write-Verbose "[$(Get-Date)] >> $_"
            
            $message = "" | select Line, Prefix, Command, ArgumentString, Arguments, Text
            
            $message.Line = $_
            $message.Prefix = $Matches[1]
            $message.Command = $Matches[2]
            $message.ArgumentString = $Matches[3]
            
            $singleWordArguments, $rest = ("dummy " + $message.ArgumentString) -split " :"
            $singleWordArguments = $singleWordArguments -split " "
            $message.Arguments = @(($singleWordArguments + $rest) | select -skip 1 | foreach { $_.Trim() })
            #write-verbose ($message.Arguments -join "|")
            
            $message.Text = ""
            
            return $message
        }
        default
        {
            Write-Warning "Unknown line >> $line"
            break
        }
    }
}

function Run-Bot ($line, $bot)
{
    $message = $line | Parse-IncomingLine $bot
    if ($message)
    {
        try
        {
            $handled = $false
            
            & $bot.BotScript $message $bot |
                foreach { $handled = $true; $_ } |
                Write-Irc $message $bot
                
            if (!$handled)
            {
                InstinctBot $message $bot |
                    Write-Irc $message $bot
            }
        }
        catch
        {
            Write-Error -ErrorRecord $_
        }
    }
}

function Main
{
    try
    {
        $bot = "" | select ServerName, ServerPort, Channel, TextEncoding, UserName, State, BotScript, Connection, NetworkStream, Reader, Writer, InteractiveDelay, InactiveDelay, Running, _MemoryStream
        
        $bot.ServerName, $bot.ServerPort = $Server -split ":"
        if (!$bot.ServerPort)
        {
            $bot.ServerPort = 6667
        }
        
        $bot.InactiveDelay = 1000
        $bot.InteractiveDelay = 200
        $bot.BotScript = $BotScript
        $bot.State = $State
        $bot.Channel = $Channel
        $bot.TextEncoding = [Text.Encoding]::ASCII
        
        if (!(Test-Path $bot.BotScript))
        {
            $bot.BotScript = $bot.BotScript + '.ps1'
        }
        
        $botScriptItem = gi $bot.BotScript
        $bot.UserName = $botScriptItem.BaseName
        $bot.BotScript = $botScriptItem.FullName
        
        Write-Verbose "Connecting to: $($bot.ServerName):$($bot.ServerPort)"
        $bot.Connection = New-Object Net.Sockets.TcpClient ($bot.ServerName, $bot.ServerPort)
        $bot.NetworkStream = $bot.Connection.GetStream()
        $bot.Reader = New-Object IO.StreamReader ($bot.NetworkStream, $bot.TextEncoding)
        $bot.Writer = New-Object IO.StreamWriter ($bot.NetworkStream, $bot.TextEncoding)
        Write-Verbose "Connected!"
        
        $bot.Running = $true
        Run-Bot "__begin" $bot
        
        try
        {
            $active = $false
            $receiveBuffer = new-object byte[] ($bot.Connection.ReceiveBufferSize)
            
            while ($bot.Running)
            {
                if ($active)
                {
                    sleep -Milliseconds $bot.InteractiveDelay
                }
                else
                {
                    sleep -Milliseconds $bot.InactiveDelay
                }
                
                $active = $false
                
                 while ($bot.Running -and ($bot.NetworkStream.DataAvailable -or $bot.Reader.Peek() -ne -1))
                {
                    $line = $bot.Reader.ReadLine()
                    if ($line -ne $null)
                    {
                        Run-Bot $line $bot
                    }
                }
            }
        }
        finally
        {
            $bot.Running = $false
            Run-Bot "__end" $bot
        }
    }
    finally
    {
        if ($bot.Connection)
        {
            Write-Verbose "Closing connection..."
            $bot.Connection.Close()
            $bot.Connection.Dispose()
        }
        
        Write-Verbose "Done!"
    }
}

Main