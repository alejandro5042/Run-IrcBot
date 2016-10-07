<#  
.SYNOPSIS  
    IRC Bot Toolkit for PowerShell
    
.DESCRIPTION  
    `Run-IrcBot.ps1` is an easy way to make IRC bots using PowerShell. Requiring no dependencies, it handles the IRC protocol so you can concentrate on the cool stuff your bot will do. If your bot is script-based, it can be edited at runtime for maximum fun and iterative development. Great for internal IRC servers. Licensed under MIT.
    
    For license and documention, see: https://github.com/alejandro5042/Run-IrcBot
    
    Copyright (c) 2014 Alejandro Barreto
    
.LINK
    https://github.com/alejandro5042/Run-IrcBot
#>

[CmdLetBinding()]
param
(
    [Parameter(Position = 0, Mandatory = $true)]
    [string]
    $Name,
    
    [Parameter(Position = 1, Mandatory = $true)]
    [string]
    $Server,
    
    [Parameter(Position = 2, Mandatory = $true)]
    [string[]]
    $Channels,
    
    [Parameter(Position = 3)]
    $BotScript,
    
    $State = @{},
    
    [switch]
    $Silent
)

#################################################################

$SOURCE_URL = "http://github.com/alejandro5042/Run-IrcBot"

$BANNER = "IRC Bot Toolkit for PowerShell -- $SOURCE_URL"

$DEFAULT_DESCRIPTION = "Based on -- $SOURCE_URL"

$API_VERSION = 1

#################################################################

$RESPONSE_CODES = @{

    # 001 Welcome to the Internet Relay Network <nick>!<user>@<host> 
    001 = 'RPL_WELCOME';

    # 002 Your host is <servername>, running version <ver> 
    002 = 'RPL_YOURHOST';

    # 003 This server was created <date> 
    003 = 'RPL_CREATED';

    # 004 <servername> <version> <available user modes> <available channel modes> 
    004 = 'RPL_MYINFO';

    # 005 Try server <server name>, port <port number> 
    005 = 'RPL_BOUNCE';

    # 302 :*1<reply> *( 
    302 = 'RPL_USERHOST';

    # 303 :*1<nick> *( 
    303 = 'RPL_ISON';

    # 301 <nick> :<away message> 
    301 = 'RPL_AWAY';

    # 305 :You are no longer marked as being away 
    305 = 'RPL_UNAWAY';

    # 306 :You have been marked as being away 
    306 = 'RPL_NOWAWAY';

    # 311 <nick> <user> <host> * :<real name> 
    311 = 'RPL_WHOISUSER';

    # 312 <nick> <server> :<server info> 
    312 = 'RPL_WHOISSERVER';

    # 313 <nick> :is an IRC operator 
    313 = 'RPL_WHOISOPERATOR';

    # 317 <nick> <integer> :seconds idle 
    317 = 'RPL_WHOISIDLE';

    # 318 <nick> :End of WHOIS list 
    318 = 'RPL_ENDOFWHOIS';

    # 319 "<nick> :*( ( "@" / "+" ) <channel> " " )" 
    319 = 'RPL_WHOISCHANNELS';

    # 314 <nick> <user> <host> * :<real name> 
    314 = 'RPL_WHOWASUSER';

    # 369 <nick> :End of WHOWAS 
    369 = 'RPL_ENDOFWHOWAS';

    # 322 <channel> <# visible> :<topic> 
    322 = 'RPL_LIST';

    # 323 :End of LIST 
    323 = 'RPL_LISTEND';

    # 325 <channel> <nickname> 
    325 = 'RPL_UNIQOPIS';

    # 324 <channel> <mode> <mode params> 
    324 = 'RPL_CHANNELMODEIS';

    # 331 <channel> :No topic is set 
    331 = 'RPL_NOTOPIC';

    # 332 <channel> :<topic> 
    332 = 'RPL_TOPIC';

    # 341 <channel> <nick> 
    341 = 'RPL_INVITING';

    # 342 <user> :Summoning user to IRC 
    342 = 'RPL_SUMMONING';

    # 346 <channel> <invitemask> 
    346 = 'RPL_INVITELIST';

    # 347 <channel> :End of channel invite list 
    347 = 'RPL_ENDOFINVITELIST';

    # 348 <channel> <exceptionmask> 
    348 = 'RPL_EXCEPTLIST';

    # 349 <channel> :End of channel exception list 
    349 = 'RPL_ENDOFEXCEPTLIST';

    # 351 <version>.<debuglevel> <server> :<comments> 
    351 = 'RPL_VERSION';

    # 352 <channel> <user> <host> <server> <nick> ( "H 
    352 = 'RPL_WHOREPLY';

    # 315 <name> :End of WHO list 
    315 = 'RPL_ENDOFWHO';

    # 353 ( "= 
    353 = 'RPL_NAMREPLY';

    # 366 <channel> :End of NAMES list 
    366 = 'RPL_ENDOFNAMES';

    # 364 <mask> <server> :<hopcount> <server info> 
    364 = 'RPL_LINKS';

    # 365 <mask> :End of LINKS list 
    365 = 'RPL_ENDOFLINKS';

    # 367 <channel> <banmask> 
    367 = 'RPL_BANLIST';

    # 368 <channel> :End of channel ban list 
    368 = 'RPL_ENDOFBANLIST';

    # 371 :<string> 
    371 = 'RPL_INFO';

    # 374 :End of INFO list 
    374 = 'RPL_ENDOFINFO';

    # 375 :- <server> Message of the day - 
    375 = 'RPL_MOTDSTART';

    # 372 :- <text> 
    372 = 'RPL_MOTD';

    # 376 :End of MOTD command 
    376 = 'RPL_ENDOFMOTD';

    # 381 :You are now an IRC operator 
    381 = 'RPL_YOUREOPER';

    # 382 <config file> :Rehashing 
    382 = 'RPL_REHASHING';

    # 383 You are service <servicename> 
    383 = 'RPL_YOURESERVICE';

    # 391 <server> :<string showing server's local time> 
    391 = 'RPL_TIME';

    # 392 :UserID Terminal Host 
    392 = 'RPL_USERSSTART';

    # 393 :<username> <ttyline> <hostname> 
    393 = 'RPL_USERS';

    # 394 :End of users 
    394 = 'RPL_ENDOFUSERS';

    # 395 :Nobody logged in 
    395 = 'RPL_NOUSERS';

    # 200 Link <version & debug level> <destination> <next server> V<protocol version> <link uptime in seconds> <backstream sendq> <upstream sendq>
    200 = 'RPL_TRACELINK';

    # 201 Try. <class> <server> 
    201 = 'RPL_TRACECONNECTING';

    # 202 H.S. <class> <server> 
    202 = 'RPL_TRACEHANDSHAKE';

    # 203 ???? <class> [<client IP address in dot form>] 
    203 = 'RPL_TRACEUNKNOWN';

    # 204 Oper <class> <nick> 
    204 = 'RPL_TRACEOPERATOR';

    # 205 Name <class> <nick> 
    205 = 'RPL_TRACEUSER';

    # 206 Serv <class> <int>S <int>C <server> <nick!user|*!*>@<host|server> V<protocol version> 
    206 = 'RPL_TRACESERVER';

    # 207 Service <class> <name> <type> <active type> 
    207 = 'RPL_TRACESERVICE';

    # 208 <newtype> 0 <client name> 
    208 = 'RPL_TRACENEWTYPE';

    # 209 Class <class> <count> 
    209 = 'RPL_TRACECLASS';

    # 261 File <logfile> <debug level> 
    261 = 'RPL_TRACELOG';

    # 262 <server name> <version & debug level> :End of TRACE 
    262 = 'RPL_TRACEEND';

    # 211 <linkname> <sendq> <sent messages> <sent Kbytes> <received messages> <received Kbytes> <time open> 
    211 = 'RPL_STATSLINKINFO';

    # 212 <command> <count> <byte count> <remote count> 
    212 = 'RPL_STATSCOMMANDS';

    # 219 <stats letter> :End of STATS report 
    219 = 'RPL_ENDOFSTATS';

    # 242 :Server Up d days d:02d:02d 
    242 = 'RPL_STATSUPTIME';

    # 243 O <hostmask> * <name> 
    243 = 'RPL_STATSOLINE';

    # 221 <user mode string> 
    221 = 'RPL_UMODEIS';

    # 234 <name> <server> <mask> <type> <hopcount> <info> 
    234 = 'RPL_SERVLIST';

    # 235 <mask> <type> :End of service listing 
    235 = 'RPL_SERVLISTEND';

    # 251 :There are <integer> users and <integer> services on <integer> servers 
    251 = 'RPL_LUSERCLIENT';

    # 252 <integer> :operator(s) online 
    252 = 'RPL_LUSEROP';

    # 253 <integer> :unknown connection(s) 
    253 = 'RPL_LUSERUNKNOWN';

    # 254 <integer> :channels formed 
    254 = 'RPL_LUSERCHANNELS';

    # 255 :I have <integer> clients and <integer> servers 
    255 = 'RPL_LUSERME';

    # 256 <server> :Administrative info 
    256 = 'RPL_ADMINME';

    # 257 :<admin info> 
    257 = 'RPL_ADMINLOC1';

    # 258 :<admin info> 
    258 = 'RPL_ADMINLOC2';

    # 259 :<admin info> 
    259 = 'RPL_ADMINEMAIL';

    # 263 <command> :Please wait a while and try again. 
    263 = 'RPL_TRYAGAIN';

    # 401 <nickname> :No such nick/channel 
    401 = 'ERR_NOSUCHNICK';

    # 402 <server name> :No such server 
    402 = 'ERR_NOSUCHSERVER';

    # 403 <channel name> :No such channel 
    403 = 'ERR_NOSUCHCHANNEL';

    # 404 <channel name> :Cannot send to channel 
    404 = 'ERR_CANNOTSENDTOCHAN';

    # 405 <channel name> :You have joined too many channels 
    405 = 'ERR_TOOMANYCHANNELS';

    # 406 <nickname> :There was no such nickname 
    406 = 'ERR_WASNOSUCHNICK';

    # 407 <target> :<error code> recipients. <abort message> 
    407 = 'ERR_TOOMANYTARGETS';

    # 408 <service name> :No such service 
    408 = 'ERR_NOSUCHSERVICE';

    # 409 :No origin specified 
    409 = 'ERR_NOORIGIN';

    # 411 :No recipient given (<command>) 
    411 = 'ERR_NORECIPIENT';

    # 412 :No text to send 
    412 = 'ERR_NOTEXTTOSEND';

    # 413 <mask> :No toplevel domain specified 
    413 = 'ERR_NOTOPLEVEL';

    # 414 <mask> :Wildcard in toplevel domain 
    414 = 'ERR_WILDTOPLEVEL';

    # 415 <mask> :Bad Server/host mask 
    415 = 'ERR_BADMASK';

    # 421 <command> :Unknown command 
    421 = 'ERR_UNKNOWNCOMMAND';

    # 422 :MOTD File is missing 
    422 = 'ERR_NOMOTD';

    # 423 <server> :No administrative info available 
    423 = 'ERR_NOADMININFO';

    # 424 :File error doing <file op> on <file> 
    424 = 'ERR_FILEERROR';

    # 431 :No nickname given 
    431 = 'ERR_NONICKNAMEGIVEN';

    # 432 <nick> :Erroneous nickname 
    432 = 'ERR_ERRONEUSNICKNAME';

    # 433 <nick> :Nickname is already in use 
    433 = 'ERR_NICKNAMEINUSE';

    # 436 <nick> :Nickname collision KILL from <user>@<host> 
    436 = 'ERR_NICKCOLLISION';

    # 437 <nick/channel> :Nick/channel is temporarily unavailable 
    437 = 'ERR_UNAVAILRESOURCE';

    # 441 <nick> <channel> :They aren't on that channel 
    441 = 'ERR_USERNOTINCHANNEL';

    # 442 <channel> :You're not on that channel 
    442 = 'ERR_NOTONCHANNEL';

    # 443 <user> <channel> :is already on channel 
    443 = 'ERR_USERONCHANNEL';

    # 444 <user> :Name not logged in 
    444 = 'ERR_NOLOGIN';

    # 445 :SUMMON has been disabled 
    445 = 'ERR_SUMMONDISABLED';

    # 446 :USERS has been disabled 
    446 = 'ERR_USERSDISABLED';

    # 451 :You have not registered 
    451 = 'ERR_NOTREGISTERED';

    # 461 <command> :Not enough parameters 
    461 = 'ERR_NEEDMOREPARAMS';

    # 462 :Unauthorized command (already registered) 
    462 = 'ERR_ALREADYREGISTRED';

    # 463 :Your host isn't among the privileged 
    463 = 'ERR_NOPERMFORHOST';

    # 464 :Password incorrect 
    464 = 'ERR_PASSWDMISMATCH';

    # 465 :You are banned from this server 
    465 = 'ERR_YOUREBANNEDCREEP';

    # 466 :You will be banned from this server 
    466 = 'ERR_YOUWILLBEBANNED';

    # 467 <channel> :Channel key already set 
    467 = 'ERR_KEYSET';

    # 471 <channel> :Cannot join channel (+l) 
    471 = 'ERR_CHANNELISFULL';

    # 472 <char> :is unknown mode char to me for <channel> 
    472 = 'ERR_UNKNOWNMODE';

    # 473 <channel> :Cannot join channel (+i) 
    473 = 'ERR_INVITEONLYCHAN';

    # 474 <channel> :Cannot join channel (+b) 
    474 = 'ERR_BANNEDFROMCHAN';

    # 475 <channel> :Cannot join channel (+k) 
    475 = 'ERR_BADCHANNELKEY';

    # 476 <channel> :Bad Channel Mask 
    476 = 'ERR_BADCHANMASK';

    # 477 <channel> :Channel doesn't support modes 
    477 = 'ERR_NOCHANMODES';

    # 478 <channel> <char> :Channel list is full 
    478 = 'ERR_BANLISTFULL';

    # 481 :Permission Denied- You're not an IRC operator 
    481 = 'ERR_NOPRIVILEGES';

    # 482 <channel> :You're not channel operator 
    482 = 'ERR_CHANOPRIVSNEEDED';

    # 483 :You can't kill a server! 
    483 = 'ERR_CANTKILLSERVER';

    # 484 :Your connection is restricted! 
    484 = 'ERR_RESTRICTED';

    # 485 :You're not the original channel operator 
    485 = 'ERR_UNIQOPPRIVSNEEDED';

    # 491 :No O-lines for your host 
    491 = 'ERR_NOOPERHOST';

    # 501 :Unknown MODE flag 
    501 = 'ERR_UMODEUNKNOWNFLAG';

    # 502 :Cannot change mode for other users 
    502 = 'ERR_USERSDONTMATCH';
}

function Write-Banner ($message)
{
    if (!$Silent)
    {
        Write-Host $message -Foreground DarkGray
        Write-Host
    }
}

function Write-BotHost ($message)
{
    if (!$Silent)
    {
        Write-Host "** $message" -Foreground DarkGray
    }
}

function InstinctBot ($message, $bot)
{
    switch ($message.Command)
    {
        'BOT_CONNECTED'
        {
            "/NICK $($bot.Nickname)"
            "/USER $($bot.Name) localhost $($bot.ServerName) :$($bot.Description)"
            break
        }
        'RPL_WELCOME'
        {
            Write-BotHost "Connected: $($message.ArgumentString)"
            break
        }
        'JOIN'
        {
            Write-BotHost "Joined: $($message.Arguments[0])"
            break
        }
        'RPL_ENDOFMOTD'
        {
            "/JOIN $($bot.Channels)"
            break
        }
        'PING'
        {
            "/PONG $($message.ArgumentString)"
            break
        }
        'ERR_ERRONEUSNICKNAME'
        {
            $bot.Running = $false
            throw 'Invalid user name.'
        }
        'ERR_NICKNAMEINUSE'
        {
            $bot.NicknameCounter += 1
            $bot.Nickname = ($message.Arguments[1] -replace "[\d]*$", "") + $bot.NicknameCounter
            "/NICK $($bot.Nickname)"
            break
        }
        'ERROR'
        {
            Write-BotHost "Quitting: $($message.Arguments[0])"
            $bot.Running = $false
            break
        }
    }
}

filter Parse-OutgoingLine ($message, $bot)
{
    $line = $_
    $target = $message.Target
    
    # Don't output a white line.
    if ($line.Trim().Length -eq 0)
    {
        return
    }
    
    if (!$target)
    {
        $target = $bot.Channels
    }
    
    if ($line -match '^/msg\s+([^\s]+)\s+(.*)')
    {
        $target = $Matches[1]
        $line = $Matches[2]
    }
    
    if ($line -match '^/me\s(.*)')
    {
        $line = "$([char]1)ACTION $($Matches[1])$([char]1)"
    }
    
    if (!$line)
    {
        $line = ''
    }
    
    if ($line.StartsWith('/'))
    {
        $line = $line.Substring(1)
        
        # See if it was escaped.
        if (!$line.StartsWith('/'))
        {
            return $line
        }
    }
    
    if (!$target)
    {
        throw "No message target: $line"
    }
    
    return "PRIVMSG $target :$line"
}

function Write-Irc ($message, $bot)
{
    begin
    {
        $wroteToIrc = $false
    }
    process
    {
        foreach ($line in ([string]$_ -split '\n') | Parse-OutgoingLine $message $bot)
        {
            if ($line -match '^pipe(?:\s(.*))?')
            {
                $Matches[1]
            }
            elseif ($bot.Writer)
            {
                if (!$wroteToIrc)
                {
                    Write-Verbose "--------------------------------------"
                    $wroteToIrc = $true
                }
            
                Write-Verbose "<< $line"
                $bot.Writer.WriteLine($line)
                $bot.Writer.Flush()
                sleep -Milliseconds $bot.InteractiveDelay
            }
            else
            {
                # We don't have a writer and we didn't write to the pipe. Ignore the message.
            }
        }
    }
    end
    {
        if ($wroteToIrc)
        {
            Write-Verbose "--------------------------------------"
        }
    }
}

filter Parse-IncomingLine ($bot)
{
    if ($_ -match "^(?:[:@]([^\s]+) )?([^\s]+)((?: ((?:[^:\s][^\s]* ?)*))?(?: ?:(.*))?)$")
    {
        $message = "" | select Line, Prefix, Command, CommandCode, ArgumentString, Arguments, Text, Target, Time, SenderNickname, SenderName, SenderHost
        
        $message.Time = (Get-Date)
        $message.Line = $_
        $message.Prefix = $Matches[1]
        $message.CommandCode = $Matches[2]
        $message.ArgumentString = $Matches[3].TrimStart()
        $message.Arguments = @(@($Matches[4] -split " ") + @($Matches[5]) | where { $_ })
        
        if ($message.Prefix -match "^(.*?)!(.*?)@(.*?)$")
        {
            $message.SenderNickname = $Matches[1]
            $message.SenderName = $Matches[2]
            $message.SenderHost = $Matches[3]
        }
        
        $message.Command = $RESPONSE_CODES[[int]($message.CommandCode -as [int])]
        if (!$message.Command)
        {
            $message.Command = $message.CommandCode
        }
        
        if ($message.Command -eq "PRIVMSG")
        {
            $message.Target = $message.Arguments[0]
            $message.Text = $message.Arguments[1]
            
            $message.Text = $message.Text -replace "^$([char]1)ACTION (.*)$([char]1)$", '/me $1' # Reset actions.
            $message.Text = $message.Text -replace "$([char]3)(?:1[0-5]|[0-9])(?:,(?:1[0-5]|[0-9]))?", '' # Remove colors.
            $message.Text = $message.Text -replace "$([char]0x02)", '' # Remove bold.
            $message.Text = $message.Text -replace "$([char]0x1D)", '' # Remove italics.
            $message.Text = $message.Text -replace "$([char]0x1F)", '' # Remove underline.
        }
        
        return $message
    }
}

filter listify
{
    (@(($_ | fl | out-string) -split "`n") | foreach { $_.Trim() } | where { $_ } | foreach { "#    $_`n" }) -join ''
}

function Run-Bot ($line, $bot, [switch]$fatal)
{
    $message = $line | Parse-IncomingLine $bot
    Write-Verbose ">> $message"
      
    try
    {
        if (!$message)
        {
            throw "Unknown command."
        }
        
        InstinctBot $message $bot |
            Write-Irc $message $bot
        
        & $bot.BotScript $message $bot |
            Write-Irc $message $bot
    }
    catch
    {
        if ($fatal)
        {
            throw
        }
        
        if (!$bot.CurrentError)
        {
            $bot.CurrentError = $_
            Write-Error "$($_.Exception.ToString())`n$($_.InvocationInfo.PositionMessage)`n# Message:`n$($message | listify)`n# Bot.State:`n$([pscustomobject]$bot.State | listify)`n# Bot:`n$($bot | listify)"
            
            if ($bot.CurrentError.CategoryInfo.Category -ne "ParserError")
            {
                Run-Bot 'BOT_ERROR' $bot
            }
        }
    }
    
    $bot.CurrentError = $null
}

function Handle-InputPipeStateMachine ($bot)
{
    # Keeps a named pipe open on the local computer.
    # Other PowerShell cmdlets can write text to it using | Out-IrcBot.ps1
    # and this reads it and sends it on to IRC through the $bot

    # Is Asynchronous to make it non-blocking. Lifecycle is:
    # 1. Create a named pipe.
    #  . Initialize variables for one message
    # 3. Async wait for connections
    # 4. Check if a connection happened, if not stay here at 4.
    # 5. Start an async Read().
    # 6. if read finished, add text to array. If not, stay here at 6.
    # 7. Check if Pipe Message is completed. If not, goto 5.
    #  . All text read, pipe message complete. Write text to IRC. Goto 2.

    # Init
    if ($null -eq $Script:InputPipeState) {
        $Script:InputPipeState = 1
    }

    # State machine
    switch ($Script:InputPipeState)
    {
        1 {
            $Script:InputPipe = new-object System.IO.Pipes.NamedPipeServerStream('ircbot_pipe',
                                                                [System.IO.Pipes.PipeDirection]::InOut,
                                                                1,  #? idk what this is for, just copypasted it
                                                                [System.IO.Pipes.PipeTransmissionMode]::Message,
                                                                [System.IO.Pipes.PipeOptions]::Asynchronous)

            $Script:InputPipeMessageBuffer = New-Object byte[] 1024        #1Kb read buffer
            $Script:InputPipeMessageBuilder = New-Object System.Text.StringBuilder

            $Script:InputPipeState = 3
        }

        3 {
            $Script:InputPipeConnectionWait = $Script:InputPipe.WaitForConnectionAsync() # wait for client

            $Script:InputPipeState = 4
        }

        4 { 
            if ($Script:InputPipeConnectionWait.IsCompleted) { # client connected
                $Script:InputPipeState = 5
            }
        }

        5 {
            $Script:InputPipeReadWait = $Script:InputPipe.ReadAsync($Script:InputPipeMessageBuffer,        #begin reading from pipe into buffer
                                                                    0,                            #store at buffer byte 0
                                                                    $Script:InputPipeMessageBuffer.Length) #max num bytes to read
            $Script:InputPipeState = 6
        }

        6 {
            if ($Script:InputPipeReadWait.IsCompleted) { # background read finished
                $NumBytesRead = $Script:InputPipeReadWait.Result
                $MessageText = [System.Text.Encoding]::UTF8.GetString($Script:InputPipeMessageBuffer, 0, $NumBytesRead)
                $null = $Script:InputPipeMessageBuilder.Append($MessageText)

                $Script:InputPipeState = 7
            }
        }

        7 {
            if (-not $Script:InputPipe.IsMessageComplete)
            {
                $Script:InputPipeState = 5 # read again
            } 
            else
            {
                $line = $Script:InputPipeMessageBuilder.ToString()
                $target = @($bot.Channels)[0]
                $line = "PRIVMSG $target :$line"
                       
                if ($bot.Writer) {
                    $bot.Writer.WriteLine($line)
                    $bot.Writer.Flush()
                }
             
                $Script:InputPipe.Close()
                $Script:InputPipe.Dispose()    
                $Script:InputPipeState = 1 # restart
            }
        }

    }
    
}

function Handle-InputPipe ($bot) {
    # As the main loop has a delay in it, this runs quickly through the entire state machine each call
    for ($i=0; $i -lt 7; $i++) {
        Handle-InputPipeStateMachine $bot
    }  
}

function Main
{
    try
    {
        Write-Banner $BANNER
        
        $bot = "" | select ServerName, ServerPort, Channels, TextEncoding, Name, State, BotScript, Connection, NetworkStream, Reader, Writer, InteractiveDelay, InactiveDelay, Running, CurrentError, TimerInterval, StartTime, LastTick, Nickname, Description, NicknameCounter, ApiVersion
        
        $bot.ApiVersion = $API_VERSION
        
        $bot.ServerName, $bot.ServerPort = $Server -split ":"
        if (!$bot.ServerPort)
        {
            $bot.ServerPort = 6667
        }
        
        if (Test-Path $Name)
        {
            $bot.Name = (gi $Name).BaseName
        }
        else
        {
            $bot.Name = $Name
        }
        
        $bot.Nickname = $bot.Name
        $bot.NicknameCounter = 1
        $bot.Description = $DEFAULT_DESCRIPTION
        $bot.Running = $false
        $bot.InactiveDelay = 1000
        $bot.InteractiveDelay = 100
        $bot.TimerInterval = 0
        $bot.BotScript = $BotScript
        $bot.State = $State
        $bot.Channels = ($Channels | where { $_ } | foreach { "#$_" }) -join ','
        $bot.TextEncoding = [Text.Encoding]::ASCII
        
        if (!$bot.BotScript)
        {
            $botScriptName = $Name
            
            if (!(Test-Path $botScriptName))
            {
                $botScriptName = $botScriptName + '.ps1'
            }
            
            if (!(Test-Path $botScriptName))
            {
                throw "Cannot find script: $botScriptName"
            }
            
            $botScriptItem = gi $botScriptName
            $bot.BotScript = $botScriptItem.FullName
        }
        
        Write-Verbose "Original Bot: $bot"
        
        # Allow the bot to initialize the bot and/or massage parameters. Plus, if the script fails to compile or statically initialize (maybe because it doesn't like a parameter), we'll quit before we even connect.
        Run-Bot 'BOT_INIT' $bot -Fatal
        Write-Verbose "Initialized Bot: $bot"
        
        try
        {
            $bot.Connection = New-Object Net.Sockets.TcpClient ($bot.ServerName, $bot.ServerPort)
            $bot.NetworkStream = $bot.Connection.GetStream()
            $bot.Reader = New-Object IO.StreamReader ($bot.NetworkStream, $bot.TextEncoding)
            $bot.Writer = New-Object IO.StreamWriter ($bot.NetworkStream, $bot.TextEncoding)
            
            $bot.StartTime = [DateTime]::Now
            $bot.Running = $true
            Run-Bot 'BOT_CONNECTED' $bot
        
            $active = $false
            $bot.LastTick = [DateTime]::Now
            
            while ($bot.Running)
            {
                Handle-InputPipe $bot

                if ($active)
                {
                    sleep -Milliseconds $bot.InteractiveDelay
                }
                else
                {
                    sleep -Milliseconds $bot.InactiveDelay
                }
                
                $active = $false
                
                if ($bot.Running -and $bot.TimerInterval)
                {
                    if ((New-TimeSpan $bot.LastTick ([DateTime]::Now)).TotalMilliseconds -gt $bot.TimerInterval)
                    {
                        Run-Bot 'BOT_TICK' $bot
                        $bot.LastTick = [DateTime]::Now
                    }
                }
                else
                {
                    $bot.LastTick = [DateTime]::Now
                }
                
                while ($bot.Running -and ($bot.NetworkStream.DataAvailable -or $bot.Reader.Peek() -ne -1))
                {
                    $line = $bot.Reader.ReadLine()
                    
                    if ($line -ne $null)
                    {
                        $active = $true
                        Run-Bot $line $bot
                    }
                }
            }
        }
        catch
        {
            $bot.CurrentError = $_
            Run-Bot 'BOT_FATAL_ERROR' $bot
            throw
        }
        finally
        {
            $bot.Running = $false
            
            try
            {
                if ($bot.Connection.Connected)
                {
                    Run-Bot 'BOT_DISCONNECTING' $bot
                }
            }
            finally
            {
                Run-Bot 'BOT_END' $bot
            }
        }
    }
    finally
    {

        if ($bot.Connection)
        {
            $bot.Connection.Close()
            $bot.Connection.Dispose()
            
            Write-BotHost "Disconnected [$([DateTime]::Now.ToString())]`n"
        }

        if ($Script:InputPipe)
        {
            $Script:InputPipe.Close()
            $Script:InputPipe.Dispose()  
        }

    }
}

Main
