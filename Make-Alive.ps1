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

    # 205 User <class> <nick> 
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

    # 444 <user> :User not logged in 
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
        'BOT_CONNECTED'
        {
            "/NICK $($bot.UserName)"
            "/USER $($bot.UserName) localhost $($bot.ServerName) ps-ircbot"
            break
        }
        'PING'
        {
            "/PONG $($message.ArgumentString)"
            break
        }
        'ERR_NICKNAMEINUSE'
        {
            $newNick = $message.Arguments[1] + "_"
            "/NICK $newNick"
            break
        }
        'RPL_LISTEND'
        {
            #"/quit haha"
            break
        }
        'RPL_ENDOFMOTD'
        {
            "/LIST"
            break
        }
        'ERROR'
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
            "$([char]1)ACTION $($Matches[1])$([char]1)" # TODO: Test this
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
    if ($_ -match "^(?:[:@]([^\s]+) )?([^\s]+)((?: ((?:[^:\s][^\s]* ?)*))?(?: ?:(.*))?)$")
    {
        Write-Verbose "[$(Get-Date)] >> $_"
        
        $message = "" | select Line, Prefix, Command, CommandCode, ArgumentString, Arguments, Text
        
        $message.Line = $_
        $message.Prefix = $Matches[1]
        $message.CommandCode = $Matches[2]
        $message.ArgumentString = $Matches[3].TrimStart()
        $message.Arguments = (@($Matches[4] -split " ") + @($Matches[5])) | where { $_ }
        
        $message.Command = $RESPONSE_CODES[$message.CommandCode]
        if (!$message.Command)
        {
            $message.Command = $message.CommandCode
        }
        
        # write-verbose ($message.Arguments -join "|")
        
        $message.Text = ""
        
        return $message
    }
}

function Run-Bot ($line, $bot)
{
    $message = $line | Parse-IncomingLine $bot
    try
    {
        if (!$message)
        {
            throw "Unknown command: $message"
        }
        
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
        $bot.LastError = $_
        Run-Bot 'BOT_ERROR' $bot
    }
}

function Main
{
    try
    {
        $bot = "" | select ServerName, ServerPort, Channel, TextEncoding, UserName, State, BotScript, Connection, NetworkStream, Reader, Writer, InteractiveDelay, InactiveDelay, Running, _MemoryStream, LastError
        
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
        Run-Bot 'BOT_CONNECTED' $bot
        
        try
        {
            $active = $false
            
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
        catch
        {
            $bot.LastError = $_
            Run-Bot 'BOT_FATAL_ERROR' $bot
        }
        finally
        {
            $bot.Running = $false
            Run-Bot 'BOT_DISCONNECTING' $bot
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
