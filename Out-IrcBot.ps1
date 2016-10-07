<#
.Synopsis
   Reads text from the pipeline, and sends it to an IRC channel 
   via a named pipe -- to --> Run-IrcBot.ps1 
.DESCRIPTION
   Long description
.EXAMPLE
   PS C:\> 'Hello World' | .\Out-IrcBot.ps1
.EXAMPLE
   PS C:\> Get-Content test.txt | .\Out-IrcBot.ps1
#>
[CmdletBinding()]
[Alias()]
Param
(
    # The text to send to IRC
    [Parameter(Mandatory=$true,
                ValueFromPipeline=$true)]
    [String]$Text
)

Process
{
    # Create and connect to a pipe
    # (This end is asynchronous and message based because the other end needs to be, and this matches it)
    # Pipe is 'InOut' direction because if you just specify a one-way pipe, you can't 
    # make it 'Message' type, unless you manually specify the permissions. This is easier.
    Write-Host -ForegroundColor Cyan "Writing: $Text"

    $pipe = New-Object System.IO.Pipes.NamedPipeClientStream('.',                      #computer
                                                                'ircbot_pipe',            #pipe name
                                                                [System.IO.Pipes.PipeDirection]::InOut,
                                                                [System.IO.Pipes.PipeOptions]::Asynchronous)

        
    $pipe.Connect(10000) #10,000 milisecond connection timeout
    $pipe.ReadMode = [System.IO.Pipes.PipeTransmissionMode]::Message     # can't specify in ctor
                                                               
    # Convert the text to a byte array and send it                        
    $Message = [System.Text.Encoding]::UTF8.GetBytes($Text)
    $pipe.write($Message, 0, $Message.Length)

    $pipe.Dispose()
}
