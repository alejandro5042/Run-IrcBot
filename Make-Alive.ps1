#[CmdLetBinding()]
param
(
    [Parameter(Mandatory = $true)]
    $BotScript,
    
    [Parameter(Mandatory = $true)]
    [string]
    $Server,
    
    [string]
    $Channel,
    
    $State = (New-Object PSCustomObject)
)

function Run-SubconsiousBot ($message, $bot)
{    
    switch ($message.Command)
    {
        "begin" {
            "/nick $($bot.UserName)"
            "/user $($bot.UserName) localhost $($bot.ServerName) ps-ircbot"
        }
        "PING" { 
            "/pong $($message.ArgumentString)"
            break
        }
        "433" # Nickname already in use.
        {
            $newNick = $message.Arguments[1] + "_"
            "/nick $newNick"
        }
        "323"
        {
            #"/quit haha"
        }
        "376"
        {
            "/list"
        }
        "error"
        {
            exit
        }
        default
        {
            # write-host $command $args
        }
    }
}

filter Write-Irc ($bot)
{
    $str = [string]$_
    
    if ($str.StartsWith('/'))
    {
        $str = $str.Substring(1)
    }
    
    $str -split '\n' | foreach {    
        Write-Verbose "<< $_"
        $bot.Writer.WriteLine($_)
        $bot.Writer.Flush()
        sleep -Milliseconds $bot.InteractiveDelay
    }
}

function Parse-Line ($line, $bot)
{
    if ($line -match "^(?::([^\s]*)\s+)?([^\s]+)(?:\s*(.*))?")
    {
        Write-Verbose "[$(Get-Date)] >> $line"
        
        $message = "" | select Prefix, Command, ArgumentString, Arguments, Text
        
        $message.Prefix = $Matches[1]
        $message.Command = $Matches[2]
        $message.ArgumentString = $Matches[3]
        
        $singleWordArguments, $rest = ("dummy " + $message.ArgumentString) -split " :"
        $singleWordArguments = $singleWordArguments -split " "
        $message.Arguments = @(($singleWordArguments + $rest) | select -skip 1 | foreach { $_.Trim() })
        #write-verbose ($message.Arguments -join "|")
        
        $message.Text = ""
        
        try
        {
            
            & $bot.BotScript $message $bot |
                foreach { $handled = $true; $_ } |
                Write-Irc $bot
                
            if (!$handled)
            {
                Run-SubconsiousBot $message $bot |
                    Write-Irc $bot
            }
        }
        catch
        {
            Write-Error $_
        }
    }
    else
    {
        Write-Warning "Unknown line >> $line"
    }
}

function Run-Bot
{
    try
    {
        $bot = "" | select ServerName, ServerPort, Channel, TextEncoding, UserName, State, BotScript, Connection, NetworkStream, Reader, Writer, InteractiveDelay, InactiveDelay, Running
        
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
        $bot.Connection = New-Object Net.Sockets.TcpClient($bot.ServerName, $bot.ServerPort)
        $bot.NetworkStream = $bot.Connection.GetStream()
        $bot.Reader = New-Object IO.StreamReader($bot.NetworkStream, $bot.TextEncoding)
        $bot.Writer = New-Object IO.StreamWriter($bot.NetworkStream, $bot.TextEncoding)
        Write-Verbose "Connected!"
        
        Parse-Line "begin" $bot
        try
        {
            $active = $false
            $bot.Running = $true
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
                
                while ($bot.Running -and ($bot.NetworkStream.DataAvailable -or $bot.Reader.Peek() -ne -1))
                {
                    Parse-Line $bot.Reader.ReadLine() $bot
                    $active = $true
                }
            }
        }
        finally
        {
            Parse-Line "end" $bot
        }
    }
    finally
    {
        Write-Verbose "Closing connection..."
        $connection.Close()
        $connection.Dispose()
        Write-Verbose "Done!"
    }
}

Run-Bot