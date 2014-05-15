[CmdLetBinding()]
param
(
    [Parameter(Mandatory = $true)]
    $BotScript,
    
    [Parameter(Mandatory = $true)]
    [string]
    $Server,
    
    [int]
    $Port = 6667,
    
    [string]
    $UserName,
    
    $State = $null
)

filter Send-Line($str)
{
    $str = [string]$str
    
    if ($str.StartsWith('/'))
    {
        $str = $str.Substring(1)
    }
    
    Write-Verbose "<< $str"
    $script:writer.WriteLine($str)
    $script:writer.Flush()
}

function Parse-Command($sender, $command, $arguments)
{
    switch ($command)
    {
        "433" # Nickname already in use.
        {
            $newNick = $arguments[1] + "_"
            "/nick $newNick"
        }
        "376"
        {
            Send-Line "/LIST"
            #"/quit haha"
        }
        default
        {
            # write-host $command $args
        }
    }
}

function Run()
{
    try
    {
        $connection = New-Object Net.Sockets.TcpClient($Server, $Port)
        $networkStream = $connection.GetStream()
        $script:reader = New-Object IO.StreamReader($networkStream, [Text.Encoding]::ASCII)
        $script:writer = New-Object IO.StreamWriter($networkStream, [Text.Encoding]::ASCII)
        
        $BotScript = (gi $BotScript)
        $user = $BotScript.BaseName
        
        Send-Line "/nick $user"
        Send-Line "/user $user localhost $Server ps-ircbot"
        
        $running = $true
        while ($running)
        {            
            while ($running -and ($networkStream.DataAvailable -or $reader.Peek() -ne -1))
            {
                $line = $reader.ReadLine().Trim()
                
                if ($line -match "^(?::([^\s]*)\s+)?([^\s]+)(?:\s*(.*))?")
                {
                    Write-Verbose ">> $line"
                    
                    $sender = $Matches[1]
                    $command = $Matches[2]
                    $arguments = $Matches[3]
                    
                    $before, $after = $arguments -split " :"
                    $before = $before -split " "
                    $arguments = $before + $after
                                        
                    try
                    {
                        Parse-Command $sender $command $arguments | Send-Line
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
            
            sleep -Milliseconds 100
            write-host "ping"
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
}

Run