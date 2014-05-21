PowerShell IRC Bots
===================

`Make-Alive.ps1` is an easy way to make IRC bots using PowerShell.

```
.\Make-Alive.ps1 name server[:port] chan1,chan2,chan3
```

Hit `Ctrl+C` to quit your bot.

Command Line Usage
------------------

Position | Option | Value
--- | :---: | ---
1 | **[-Name]** *name* | **Required.** The user and nickname of your bot. If -BotScript is not provided, then this is also the name of the script. If you pass a file, the user and nickname used is the basename of the file (no path, no extension).
2 | **[-Server]** *server[:port]* | **Required.** The server to connect to with optional port. The default port is 6667 (defacto standard).
3 | **[-Channel]** *chan1,chan2,...* | **Required.** A comma-delimited list of channels your bot will join on startup, without leading `#`.
4 | **[-BotScript]** *script* | An invokable script that represents your bot. This can be the name of the script or a script block. By default, the -Name is used.
* | **-State** *object* | Initial state to pass into `$Bot.State`. The default state is an empty hash.
* | **-Silent** | Disables default host output.
* | **-Verbose** | Enables verbose output for the IRC bot.

How to Write a Bot
------------------

### Overview

Bots are written as PowerShell scripts. See the `examples/` for example bots.

The simplest bot is as follows:

```PowerShell
params($Message, $Bot)

if ($Message.Text -match "hi")
{
  "hello!"
}
```

### The `$Message` Object

asdf

### The `$Bot` Object

asdf

### Recommended Practices

asdf


FAQ
---

#### Why didn't you use filters to parse the IRC input? (begin/process/end) IRC bots seem perfect for filters!

Yes, they do! But I wanted the ability to reload the bot script at any time. If I had designed it for pipeline scripts, then I would be unable to update the script as the developer edits it. It is far more fun to interactively write your bot than to have to restart the bot server every time.

#### Why is your script using blocking I/O? Why is it single-threaded?

Because it was easier :) And hitting `Ctrl+C` still worked. Since PowerShell is already single-threaded without tricks, I didn't want to overcomplicate things. It is also important not to take more than ~20 seconds to complete a command or your IRC bot may timeout if a PING is active. I do not yet priority sort incoming messages, so you may timeout while processing a long string of messages if you take too long. The bot server can probably get DOS'ed pretty easily so beware.





