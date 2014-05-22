# IRC Bot Toolkit for PowerShell

`Run-IrcBot.ps1` is an easy way to make IRC bots using PowerShell. Requiring no dependencies, it handles the IRC protocol so you can concentrate on the cool stuff your bot will do. If your bot is script-based, it can be edited at runtime for maximum fun and iterative development. Great for internal IRC servers. Licensed under MIT.

<pre>
<b>.\Run-IrcBot.ps1</b> name server[:port] chan1,chan2,chan3
</pre>

Hit `Ctrl+C` to quit your bot.

## Installing

Run this command to download a local copy:

```PowerShell
Invoke-WebRequest 'https://raw.githubusercontent.com/alejandro5042/Run-IrcBot/master/Run-IrcBot.ps1' -OutFile Run-IrcBot.ps1
```

You can also use the `Download ZIP` or `Clone in Desktop` buttons on right-hand side of the GitHub page. Feel free to clone this repository! Contributions are welcomed.

You will need [PowerShell 4.0](http://www.microsoft.com/en-us/download/details.aspx?id=40855).

## Command Line Usage

Position | Option | Value
:---: | --- | ---
1 | **[-Name]** *name* | **Required.** The user and nickname of your bot. If **-BotScript** is not provided, then this is also the name of the script. If you pass a file, the user and nickname used is the basename of the file (no path, no extension). If the nickname is already taken, we append a number to the end of it.
2 | **[-Server]** *server[:port]* | **Required.** The server to connect to with optional port. The default port is 6667 (defacto standard).
3 | **[-Channel]** *chan1,chan2,...* | **Required.** A comma-delimited list of channels your bot will join on startup, without leading `#`.
4 | **[-BotScript]** *script* | An invokable script that represents your bot. This can be the name of the script or a script block. By default, the **-Name** is used.
* | **-State** *object* | Initial state to pass into `$Bot.State`. The default state is an empty hash table.
* | **-Silent** | Disables default host output.
* | **-Verbose** | Enables verbose output for the IRC bot.

How to Write a Bot
------------------

To begin, here's your hello world bot. Anytime someone says `hi` we will output `hello!`. Anything that is written to the output is stringified and sent via IRC.

```PowerShell
param ($Message, $Bot)

if ($Message.Text -match "hi")
{
    "hello!"
}
```

Save this as `hellobot.ps1`. To test your bot, connect to your IRC server and join the `hellobottest` channel. Now you can run your bot!

```PowerShell
.\Run-IrcBot.ps1 hellobot ircserver hellobottest
```

### Live Editing

You can edit your bot on the fly. You do not need to restart your server! If you make a mistake, the bot server will give you plenty of error message details for you to diagnose the problem. Using the **-Verbose** option will also show you all the messages your bot is receiving&mdash;very helpful during development!

So let's add another condition:

```PowerShell
param ($Message, $Bot)

if ($Message.Text -match "hi")
{
    "hello!"
}
if ($Message.Text -match "bye")
{
    "/quit"
}
```

Any output that begins with a `/` denotes an IRC command; otherwise, your output is a `PRIVMSG` reply. A double `//` escapes if you actually want to output that character as a message.

Now type `bye` in your channel. Your bot should automatically disconnect.

### Recommended Practices

As your bot gets more complicated, you may want to use a [switch statement](http://technet.microsoft.com/en-us/library/ff730937.aspx):

```PowerShell
param ($Message, $Bot)

switch -regex ($Message.Text)
{
    "hi"   { "hello" }
    "lol"  { "glad you're happy!" }
    "bye"  { "/quit cya!" }
    default
    {
        # Do nothing?
    }
}
```

Beware that the switch falls-through by default. You may prefix your output with `return` or use the `break` keyword at the end of your cases.

You can also "call out" to your bot so that it only responds to messages like `botname: do something`.

```PowerShell
param ($Message, $Bot)

switch -regex ($Message.Text)
{
    "^$($Bot.Nickname):(.*)"
    {
        switch -regex ($Matches[1])
        {
            "hi"   { "hello" }
            "lol"  { "glad you're happy!" }
            "bye"  { "/quit cya!" }
        }
    }
}
```

*Tip:* Want to be a little more dynamic? Use [Get-Random](http://technet.microsoft.com/en-us/library/hh849905.aspx):

```PowerShell
# Outputs a random element from this array.
@('hey!', 'hi', 'hello', 'sup?') | Get-Random
```

### Sending Multiple Messages

Remember, anything you write to the output is sent via IRC. You send multiple messages by outputting multiple times. You can printf-style debug your bot by using [Write-Host](http://technet.microsoft.com/en-us/library/hh849877.aspx) to write to the command line. [Write-Verbose](http://technet.microsoft.com/en-us/library/hh849951.aspx) is also useful for dumping lots of debug information; use `-Verbose` to enable.

```PowerShell
param ($Message, $Bot)

switch -regex ($Message.Text)
{
    "hi"
    {
        "hello, $($Message.SenderNickname)!"
        "how are you doing?"
    }
    default
    {
        Write-Host "Unknown message: $($Message.Text)"
    }
}
```

You can also send messages to the bot server pipeline. See `/pipe` later in the README.

### Redirecting Sub-Command Output

It is useful to run regular PowerShell commands for a reply. Remember, any output written from your script will be sent via IRC:

```PowerShell
param ($Message, $Bot)

switch -regex ($Message.Text)
{
    "cpuinfo"
    {
        # Run the `cpuinfo` command. By default, its output is our output :)
        cpuinfo
    }
    "cpudata"
    {
        # Get processor system counter data.
        Get-Counter -Counter "\Processor(_Total)\*" | foreach CounterSamples | select Path, CookedValue
    }
}
```

You will notice though that the output for the `cpudata` message looks different than it would if run on the command-line. That's because it's streaming a list of objects that we are stringifying individually. If we want it to look as it does on the command-line, use [Out-String](http://technet.microsoft.com/en-us/library/hh849952.aspx).

```PowerShell
Get-Counter -Counter "\Processor(_Total)\*" | foreach CounterSamples | select Path, CookedValue | Out-String -Stream
```

As long as you use Out-String, you can get crazy and use [Format-Table](http://technet.microsoft.com/en-us/library/hh849892.aspx), [Format-List](http://technet.microsoft.com/en-us/library/hh849957.aspx), and [Format-Wide](http://technet.microsoft.com/en-us/library/hh849918.aspx) cmdlets to make nicer output!

### Handling Commands

Besides messages, bots can respond to IRC commands. For instance, your bot can post a message anytime someone joins the channel.

```PowerShell
param ($Message, $Bot)

switch ($Message.Command)
{
    "join"
    {
        if ($Message.SenderNickname -ne $Bot.Nickname) # Don't say hello to ourselves!
        {
            "hey there $($Message.SenderNickname), what's up?"
        }
    }
}
```

A list of commands can be found later in the README.

### Stateful Bots

Since every message runs a new instance of your script, you can use `$Bot.State` to preserve state between calls.

```PowerShell
param ($Message, $Bot)

++$Bot.State.Counter
"I have seen $($Bot.State.Counter) messages."
```

*Note:* You may notice that you see more messages than you expect. This is because commands are also messages.

The default state is an empty hash table you can use it as a dynamic variable. By default, any unknown entries in a hash table are `$null`. You can index the hash table as an object (`$map.xyz`) or with square-brackets (`$map['xyz']`).

If you wish, you can initialize the state on `BOT_INIT`.

```PowerShell
param ($Message, $Bot)

switch ($Message.Command)
{
    "BOT_INIT"
    {
        $Bot.State.Counter = 1000
    }
}

++$Bot.State.Counter
"I have seen $($Bot.State.Counter) messages."
```

### Command-Line Bots

I thought it would be fun to experiment with command-line bots. You can specify a command-line bot with **-BotScript** (the default fourth parameter). This simple bot tries to match any string that contains a TFS changeset number and replies with its details.

```PowerShell
.\Run-IrcBot.ps1 tfsbot ircserver channel { if ($Message.Text -match "change(?:set)?\s+(\d+)") { Get-TfsChangeset $Matches[1] | select ChangesetId, CreationDate, Owner, Comment } }
```

This bot redirects any messages to the pipeline. The [sls](http://technet.microsoft.com/en-us/library/hh849903.aspx) command filters for messages containing `amazing`.

```PowerShell
.\Run-IrcBot.ps1 monitor ircserver channel { if ($message.Text) { "/pipe " + $message.Text } } -Silent | sls amazing
```

You can also use the command-line option to use another script or pass arguments to your script.

```PowerShell
.\Run-IrcBot.ps1 awesomebot ircserver channel superbot
.\Run-IrcBot.ps1 awesomebot ircserver channel { .\superbot.ps1 $Message $Bot -DoAwesomeStuff }
```

## Specification

Using the **-Verbose** option will help you understand how these objects work and the behaviors of each of the commands.

### The `$Message` Object

A new instance is constructed with every message. Not all messages will populate the entire object. For example, if the line does not contain a prefix, then the prefix and the sender info will all be `$null`.

Name | Sample Value | Notes
--- | --- | ---
$Message.**ArgumentString** | #channel :my message
$Message.**Arguments**      | {#channel, my message}
$Message.**Command**        | PRIVMSG | A friendly string representation of `$Bot.CommandCode`, otherwise just a copy of `$Message.CommandCode`.
$Message.**CommandCode**    | PRIVMSG | The actual command in the IRC line. For the known numeric replies in the IRC RFC specs, I translate it into a string and store it in `$Bot.Command`. See the `Run-IrcBot.ps1` code for a listing of these translations.
$Message.**Line**           | nick!~user@machine.com PRIVMSG #channel | The full line from the IRC server.
$Message.**Prefix**         | nick!~user@machine.com
$Message.**SenderHost**     | machine.com
$Message.**SenderName**     | ~user
$Message.**SenderNickname** | nick
$Message.**Target**         | #channel
$Message.**Text**           | my message | Message text if it is a `PRIVMSG`, otherwise `$null`. The text is stripped of any known formatting. If it is a `/me` message, a `/me` is prefixed.
$Message.**Time**           | 5/21/2014 3:20:32 PM | Message receive time.

### The `$Bot` Object

The same instance is used throughout the lifetime of your bot.

Name | Sample Value | Notes
--- | --- | ---
$Bot.**ApiVersion**        | 1 | Increments when breaking changes to the bot API have been introduced.
$Bot.**BotScript**        | C:\bots\awesomebot.ps1
$Bot.**Channels**         | {#channel, #channel2} | List of channels passed in by the command-line. [related [#4](https://github.com/alejandro5042/Run-IrcBot/issues/4)]
$Bot.**Connection**       | [Net.Sockets.TcpClient] | *Advanced users only!*
$Bot.**CurrentError**     | [Management.Automation.ErrorRecord] | Diagnose an error thrown in the previous run of your bot. Set before running the `BOT_ERROR` or `BOT_FATAL_ERROR` command, cleared afterward. Typically `$null`.
$Bot.**Description**      | *(Link to this repository)* | Corresponds to the IRC `realname` in the `USER` command.
$Bot.**InactiveDelay**    | 1000 | Polling interval in milliseconds between when no messages have been received recently.
$Bot.**InteractiveDelay** | 100 | Milliseconds to wait between reads/writes when currently processing messages. Useful for not getting kicked out for spamming.
$Bot.**LastTick**         | 5/21/2014 3:20:32 PM | The last time we sent a `BOT_TICK` if `$Bot.TimerInterval` is nonzero; otherwise, the current time.
$Bot.**Name**             | awesomebot | The original name of the bot; also the user name.
$Bot.**NetworkStream**    | [Net.Sockets.NetworkStream] | *Advanced users only!*
$Bot.**Nickname**         | awesomebot2 | The nickname of the bot after initial connection and conflict resolution.
$Bot.**NicknameCounter**  | 2 | How many times we attempted to find a nickname.
$Bot.**Reader**           | [IO.StreamReader] | *Advanced users only!*
$Bot.**Running**          | $True | Set to `$False` to quit immediately.
$Bot.**ServerName**       | ircserver
$Bot.**ServerPort**       | 6667
$Bot.**StartTime**        | 5/21/2014 3:11:10 PM | Set once a connection has been established.
$Bot.**State**            | { } | Scratch space for your bot that persists between calls to your script.
$Bot.**TextEncoding**     | [Text.ASCIIEncoding] | Text encoding used to communicate with server.
$Bot.**TimerInterval**    | 0 | Milliseconds between `BOT_TICK` commands. Set to nonzero to activate the timer.
$Bot.**Writer**           | [IO.StreamWriter] | *Advanced users only!*

### Output Messages

Name | Action
--- | ---
**/msg** *target* *text* | Like the IRC client command, sends *text* to *target*. *text* can also be a `/me`.
**/me** *action* | Like the IRC client command, specifies an *action*.
**/pipe** *value* | Outputs the string *value* to the PowerShell pipeline and not IRC. [related [#6](https://github.com/alejandro5042/Run-IrcBot/issues/6)]
**/cmd** *line* | Sends the IRC command `cmd` with the argument string `line`. Be sure to follow the IRC protocol.
**//** *anything* | Escapes the `/` and outputs `/ anything`.
*anything else* | Sends a `PRIVMSG` to `$Message.Target`.

*Note:* IRC command arguments are delimited by spaces. To send text, prefix with `:`. For example, the `/quit` message takes a single argument for the quit message. Without a leading `:`, it will take the last argument--typically the last word of your message. The right way to do a `/quit` message is like this:

```
/quit :my quit message
```

For a list of IRC commands, see [Wikipedia](https://en.wikipedia.org/wiki/List_of_Internet_Relay_Chat_commands).

### Commands

Bot server specific commands:

`$Message.Command` | Description
--- | ---
**BOT_INIT** | Run before connecting to the server. A good time to initialize variables, massage the `$Bot` variable, etc.
**BOT_CONNECTED** | Run after a successful connection to the server. Do not send messages at this point; instead wait for the end of the welcome message by command `RPL_ENDOFMOTD`.
**BOT_TICK** | Run when a bot tick occurs, to the resolution of `$Bot.InactiveDelay` or longer if processing commands. The interval is specified by `$Bot.TimerInterval` and is only active when it is nonzero.
**BOT_ERROR** | Run when a non-parse error occurs. See `$Bot.CurrentError`.
**BOT_FATAL_ERROR** | Run when a fatal error occurs and the bot must exit. See `$Bot.CurrentError`.
**BOT_DISCONNECTING** | Run right before disconnecting from the server *and* if the connection is still active. You can still send messages.
**BOT_END** | The last command that gets run. The connection may still be active. This command will always run if `BOT_INIT` ran successfully.

For a list of parsed IRC command replies, see the source code for `.\Run-IrcBot.ps1`. The bot server will only translate the names of these commands; the original is left in `$Message.CommandCode`.

You can also refer to these resources:

- [RFC 1459: Internet Relay Chat Protocol](https://tools.ietf.org/html/rfc1459)
- [RFC 2812: Internet Relay Chat: Client Protocol](https://tools.ietf.org/html/rfc2812)
- [Helpful document of known responses.](https://www.alien.net.au/irc/irc2numerics.html)

### Default Behavior

These default behaviors occur before your bot is run with the same command. You cannot override these behaviors.

#### BOT_CONNECTED

Sends the `NICK` and `USER` commands.

#### RPL_ENDOFMOTD

Signifies that we have authenticated successfully and that the welcome messages are done. Sends the `JOIN` command with the initial channel list provided.

#### PING

The bot will respond to `PING` messages. It is also important not to take more than ~20 seconds to complete a command or your IRC bot may timeout if a `PING` is active. I don't priority sort incoming messages, so you may timeout while processing a long string of messages if you take too long [[#2](https://github.com/alejandro5042/Run-IrcBot/issues/2)]. The bot server can probably get DOS'ed pretty easily so beware.

#### ERR_ERRONEUSNICKNAME (User Conflict)

The bot will quit if the user name is already in use.

#### ERR_NICKNAMEINUSE (Nickname Conflict)

The bot will add a number (`$Bot.NicknameCounter`) to the end of the name provided and try again. It will increment this number until there is no conflict. The `$Bot.Nickname` contains the final nickname.

#### ERROR

The bot will output the error message and quit, still running at least `BOT_END`.

## FAQ

#### Why didn't you use filters to parse the IRC input? (begin/process/end) IRC bots seem perfect for filters!

Yes, they do! But I wanted the ability to reload the bot script at any time. If I had designed it for pipeline scripts, then I would be unable to reload the bot as the developer edits it. It is *wayyyyy* more fun to interactively write your bot than to have to restart the bot server every time. Plus it results in smaller code and makes it easier to explain to new PowerShell users.

In this project, I optimized for fun and flexibility over bullet-proof architecture. That is why there are only two flat objects (`$Message` and `$Bot`) that do most of the work. It's easy to reason with and I want the developer to care more about their bot than my toolkit. The mental overhead should be very small.

#### Why is your script using blocking I/O? Why is it single-threaded?

Because it was easier :) And hitting `Ctrl+C` still worked. Since PowerShell is already single-threaded without tricks, I didn't want to overcomplicate things. This may change in the future [[#3](https://github.com/alejandro5042/Run-IrcBot/issues/3)].
