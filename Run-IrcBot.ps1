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
    
    $State
)

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
    }
    $writer.Flush()
}

function Run-SubconsiousBot ($message, $command, $state)
{
    switch ($command)
    {
        "433" # Nickname already in use.
        {
            $newNick = $arguments[1] + "_"
            "/nick $newNick"
        }
        "323"
        {
            "/quit haha"
        }
        "376"
        {
            "/list"
        }
        "error"
        {
            throw $arguments[0]
        }
        default
        {
            # write-host $command $args
        }
    }
}

function Parse-Command ($command, $state, $botScript)
{
    $message = ''
    & $botScript $message $command $state | foreach { $outputted = $true; $_ }
    if (!$outputted)
    {
        Run-SubconsiousBot $message $command $state
    }
}

try
{
    $serverName, $port = $Server -split ":"
    if (!$port)
    {
        $port = 6667
    }
    
    $connection = New-Object Net.Sockets.TcpClient($serverName, $port)
    $networkStream = $connection.GetStream()
    $reader = New-Object IO.StreamReader($networkStream, [Text.Encoding]::ASCII)
    $writer = New-Object IO.StreamWriter($networkStream, [Text.Encoding]::ASCII)
    
    if (!(Test-Path $BotScript))
    {
        $BotScript = $BotScript + '.ps1'
    }
    $BotScript = (gi $BotScript)
    $user = $BotScript.BaseName
    $BotScript = $BotScript.FullName
    
    "/nick $user" | Out-Irc $writer
    "/user $user localhost $Server ps-ircbot" | Out-Irc $writer
    
    $running = $true
    while ($running)
    {
        sleep -Milliseconds 100
        
        while ($running -and ($networkStream.DataAvailable -or $reader.Peek() -ne -1))
        {
            $line = $reader.ReadLine().Trim()
            
            if ($line -match "^(?::([^\s]*)\s+)?([^\s]+)(?:\s*(.*))?")
            {
                Write-Verbose ">> $line"
                
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
                $arguments = $arguments | select -skip 1 | foreach { $_.Trim() }
                write-verbose ($arguments -join "|")
                
                try
                {
                    Parse-Command $type $State $BotScript | Out-Irc $writer
                }
                catch
                {
                    if ($_.FullyQualifiedErrorId -eq "ScriptHalted")
                    {
                        $running = $false
                    }
                    else
                    {
                        Write-Error $_
                    }
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
    if ($connection.Active)
    {
        $connection.Close()
    }
    $connection.Dispose()
}