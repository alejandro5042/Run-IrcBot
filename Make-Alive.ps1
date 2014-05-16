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
    
    $State = (new-object pscustomobject)
)

$sleepDelay = 1000
$interactiveDelay = 200

filter Out-Irc ($writer)
{
    $str = [string]$_
    
    if ($str.StartsWith('/'))
    {
        $str = $str.Substring(1)
    }
    
    $str -split '\n' | foreach {    
        Write-Verbose "<< $_"
        $writer.WriteLine($_)
        $writer.Flush()
        sleep -Milliseconds $interactiveDelay
    }
}

function Run-SubconsiousBot ($message, $command)
{
    switch ($command)
    {
        "PING" { 
            "/pong :$($arguments[0])"
            break
        }
        "433" # Nickname already in use.
        {
            $newNick = $arguments[1] + "_"
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

function Parse-Command ($command, [ref]$state, $botScript, $botArgs)
{
    $message = ''
    & $botScript $message $command ([ref]$state) @botArgs | foreach { $outputted = $true; $_ }
    if (!$outputted)
    {
        Run-SubconsiousBot $message $command
    }
}

try
{
    $serverName, $port = $Server -split ":"
    if (!$port)
    {
        $port = 6667
    }
    
    Write-Verbose "Connecting to: $serverName`:$port"
    $connection = New-Object Net.Sockets.TcpClient($serverName, $port)
    $networkStream = $connection.GetStream()
    $reader = New-Object IO.StreamReader($networkStream, [Text.Encoding]::ASCII)
    $writer = New-Object IO.StreamWriter($networkStream, [Text.Encoding]::ASCII)
    Write-Verbose "Connected!"
    
    if (!(Test-Path $BotScript))
    {
        $BotScript = $BotScript + '.ps1'
    }
    $BotScript = (gi $BotScript)
    $user = $BotScript.BaseName
    $BotScript = $BotScript.FullName
    
    "/nick $user" | Out-Irc $writer
    "/user $user localhost $Server ps-ircbot" | Out-Irc $writer
    
    $active = $false
    while ($true)
    {
        if ($active)
        {
            sleep -Milliseconds $interactiveDelay
        }
        else
        {
            sleep -Milliseconds $sleepDelay
        }
        
        while ($networkStream.DataAvailable -or $reader.Peek() -ne -1)
        {
            $active = $true
            $line = $reader.ReadLine().Trim()
            
            if ($line -match "^(?::([^\s]*)\s+)?([^\s]+)(?:\s*(.*))?")
            {
                Write-Verbose "[$(Get-Date)] >> $line"
                
                $Command = [PSCustomObject]@{
                    Sender = "";
                    Type = ""
                }
                
                $sender = $Matches[1]
                $type = $Matches[2]
                $arguments = $Matches[3]
                
                $Command.Type = $type
                
                $singleWordArguments, $rest = "dummy $arguments" -split " :"
                $singleWordArguments = $singleWordArguments -split " "
                $arguments = $singleWordArguments + $rest
                $arguments = @($arguments | select -skip 1 | foreach { $_.Trim() })
                #write-verbose ($arguments -join "|")
                
                try
                {
                    Parse-Command $type ([ref]$State) $BotScript | Out-Irc $writer
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
    }
}
finally
{
    Write-Verbose "Closing connection..."
    $connection.Close()
    $connection.Dispose()
    Write-Verbose "Done!"
}
