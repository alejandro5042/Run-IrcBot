IRC Bots for PowerShell
=======================

`Make-Alive.ps1` is an easy way to make IRC bots using PowerShell. If your bot is script-based, your bot can be live-edited at runtime.

```
.\Make-Alive.ps1 name server[:port] chan1,chan2,chan3
```

Hit `Ctrl+C` to quit your bot.

Command Line Usage
------------------

Position | Option | Value
:---: | --- | ---
1 | **[-Name]** *name* | **Required.** The user and nickname of your bot. If -BotScript is not provided, then this is also the name of the script. If you pass a file, the user and nickname used is the basename of the file (no path, no extension).
2 | **[-Server]** *server[:port]* | **Required.** The server to connect to with optional port. The default port is 6667 (defacto standard).
3 | **[-Channel]** *chan1,chan2,...* | **Required.** A comma-delimited list of channels your bot will join on startup, without leading `#`.
4 | **[-BotScript]** *script* | An invokable script that represents your bot. This can be the name of the script or a script block. By default, the -Name is used.
* | **-State** *object* | Initial state to pass into `$Bot.State`. The default state is an empty hash.
* | **-Silent** | Disables default host output.
* | **-Verbose** | Enables verbose output for the IRC bot.

How to Write a Bot
------------------

To begin, here's your hello world bot. Any time someone says `hi` we will output `hello!`. Anything that is written to the output is stringified and sent via IRC.

```PowerShell
param ($Message, $Bot)

if ($Message.Text -match "hi")
{
    "hello!"
}
```

Save this as `hellobot.ps1`. Now connect to your IRC server and join the `hellobottest` channel. Now you can test your bot!

```PowerShell
.\Make-Alive hellobot ircserver hellobottest
```

### Live Editing

You can edit your bot on the fly. You do not need to restart your server! If you make a mistake, the bot server will give you plenty of error message details for you to diagnose the problem.

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

Any output that begins with a `/` denotes an IRC command. Otherwise, your output is a reply). A double `//` escapes if you actually want to output that character as a message.

Now type `bye` in your channel. Your bot should automatically disconnect.

### Recommended Parsing Practices

As your bot gets more complicated, you may want to use a [switch statement](http://technet.microsoft.com/en-us/library/ff730937.aspx):

```PowerShell
param ($Message, $Bot)

switch -regex ($Message.Text)
{
    "hi"   { "hello" }
    "lol"   { "glad you're happy!" }
    "bye"  { "/quit :bye guys" }
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
            "lol"   { "glad you're happy!" }
            "bye"  { "/quit :bye guys" }
        }
    }
}
```

*Tip:* Want to be a little more dynamic? Use [`Get-Random`](http://technet.microsoft.com/en-us/library/hh849905.aspx):

```PowerShell
# Outputs a random element from this array.
@('hey!', 'hi', 'hello', 'sup?') | Get-Random
```

### Sending Multiple Messages

Remember, anything you write to the output is sent via IRC. You send multiple messages by outputting multiple times. You can `printf` diagnose your bot by using [`Write-Host`](http://technet.microsoft.com/en-us/library/hh849877.aspx) to write to the command line. [`Write-Verbose`](http://technet.microsoft.com/en-us/library/hh849951.aspx) is also useful for dumping lots of debug information; use `-Verbose` to enable.

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

### Redirecting Sub-Commands Output

It is useful to run regular PowerShell commands and redirect their output to IRC. Remember, any output written will be sent via IRC:

```PowerShell
param ($Message, $Bot)

switch -regex ($Message.Text)
{
    "cpuinfo"
    {
        # Run the `cpuinfo` command. By default, it's output is our output :)
        cpuinfo
    }
    "cpuusage"
    {
        # Get some processor system counter info.
        Get-Counter -Counter "\Processor(_Total)\*" | foreach CounterSamples | select Path, CookedValue
    }
}
```

You will notice though that the output for the `cpuusage` message looks different than it would if run on the command-line. That's because it's streaming a list of objects that we are stringifying individually. If we want it to look as it does on the command-line, use [Out-String](http://technet.microsoft.com/en-us/library/hh849952.aspx).

```PowerShell
Get-Counter -Counter "\Processor(_Total)\*" | foreach CounterSamples | select Path, CookedValue | Out-String -Stream
```

As long as you use `Out-String`, you can get crazy and use `Format-Table` and `Format-List` to make nicer output too!

### Handling Commands

asdf

### Stateful Bots

Since every message runs a new instance of your script, you can use `$Bot.State` to preserve state between calls.

```PowerShell
param ($Message, $Bot)

++$Bot.State.Counter
"I have seen $($Bot.State.Counter) messages."
```

*Note:* You may notice that you see more messages than you expect. This is because commands are also messages.

Since the default state is an empty hash, you can use it as a dynamic variable. By default, any unknown entries in a hash are `$null`. You can index the hash table as an object (`$hash.xyz`) or with square-brackets (`$hash['xyz']`).

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

asdf

You can also use the command-line option to pass arguments to your actual script.

```PowerShell
.\Make-Alive.ps1 awesomebot ircserver channel { .\awesome-bot.ps1 $Message $Bot -DoAwesomeStuff }
```

Specification
-------------

### The `$Message` Object

asdf

### The `$Bot` Object

asdf

### Output Messages

/pipe
/...

### Commands

A list of commands is

### Default Behavior

Nickname conflicts


FAQ
---

#### Why didn't you use filters to parse the IRC input? (begin/process/end) IRC bots seem perfect for filters!

Yes, they do! But I wanted the ability to reload the bot script at any time. If I had designed it for pipeline scripts, then I would be unable to update the script as the developer edits it. It is *wayyyyy* more fun to interactively write your bot than to have to restart the bot server every time.

#### Why is your script using blocking I/O? Why is it single-threaded?

Because it was easier :) And hitting `Ctrl+C` still worked. Since PowerShell is already single-threaded without tricks, I didn't want to overcomplicate things. It is also important not to take more than ~20 seconds to complete a command or your IRC bot may timeout if a PING is active. I don't priority sort incoming messages, so you may timeout while processing a long string of messages if you take too long. The bot server can probably get DOS'ed pretty easily so beware.
