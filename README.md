# HackRshell

## The R Reverse Shell 

This project implements a basic reverse shell in R. When a target runs the `hRs.client()` function in this package (either directly or on attachment of the *Completely.Innocent.Library* package), their R session will attempt to reach out to a server running the `hRs.server()` function. If the server is listening, the user behind the server will then be able to send commands to traverse the target's directory, upload or exfiltrate files, and make system calls. A full list of commands can be found below.

This reverse shell is written entirely in base R, with no additional packages needing to be installed. (Even installing the *HackRshell* package is optional if you run the source files instead.) The *Completely.Innocent.Library* package is a custom-built malicious package designed exclusively to execute the `hRs.client()` function when the package is attached. This is to demonstrate how a target could unsuspectingly open the connection. It is not necessary to install this library to run the reverse shell, see the **Usage** section below. 

This software is offered free of charge and open-source.

## Contents:

 - **README.md**

 - **LICENSE** - this software is under the GNU Lesser General public license (LGPL). See the file for deatils.

 - **HackRshell-Server.R** - This file contains the `hRs.server()` function that the user runs to listen for reverse shell connections. A user may either load the function and call it via the R terminal, or simply run `source("./HackRshell-Server.R")`, assuming the working directory contains this file.

 - **HackRshell-Client.R** - this file contains the `hRs.client()` function that the target runs to start the reverse shell session. While one can load the function and call it via the R terminal, running `source("./HackRshell-Client.R")` will do the same thing, assuming that the working directory contains this file.

 - **HackRshell** - this folder contains the R project and all the data for the HackRshell custom package, which contains a **HackRshell/R/HackRshell-Server.R** file and a **HackRshell/R/HackRshell-client.R** file. These are nearly identical to the files in the top-level directory, except that they do not contain the function call, so `source()` will not run the functions in either of them. A user needs to run the functions themselves after installing and attaching this HackRshell package. This package will *not* start the reverse shell when loaded with the `library(HackRshell)` call. 

 - **HackRshell_0.1.0.tar.gz** - a compressed file of the *HackRshell* package, ready for installation. You will need the rtools package to install this, which you can find [here](https://cran.r-project.org/bin/windows/Rtools/). Once that's downloaded, instructions for installing the package can be found in [this StackOverflow thread](https://stackoverflow.com/questions/4739837/how-do-i-install-an-r-package-from-the-source-tarball-on-windows).

 - **Completely.Innocent.Library** - this folder contains the R project and all the data for a custom R package called *Completely.Innocent.Library*. This package contains a **HackRshell-Client.R** file, identical to the one in the top level of the repository except with the function call at the end removed. This package was built to execute the `hRs.client()` function when the target installs the package and calls `library("Completely.Innocent.Library")`. You can see the code for this autorun in **Completely.Innocent.Library/R/zzz.R**. This package *will* start the reverse shell when loaded with the `library()` function. Note that when this package is attached, it will print "Loading library... (this can sometimes take several minutes)". This is completely false; the statement is meant to buy the attacker some time to use the reverse shell.

 - **Completely.Innocent.Library_0.1.0.tar.gz** - a compressed file of the *Completely.Innocent.Library* package, ready for installation. See above for installation instructions. 

## Usage: 

To run this program, you will need to have R installed. To start the server, simply open an R session and call the `hRs.server()` function. This will start the server listening. From there it's simply a matter of waiting for someone to run the `hRs.client()` function with the correct address and port.

Since it's safe to assume you are probably demonstrating this on your own machine, you can open a second R session and run the `hRs.client()` function yourself. You can either run the function manually, or you can attach the malicious package with the command `library(Completely.Innocent.Library)`. This will automatically start the `hRs.client()` function with the parameters baked into the library, so if you want to change the ip address or ports that the server is on from the defaults, you will need to rebuild the library after every change. (The defaults are for running on localhost, i.e. two R sessions on one machine,)

Once the `hRs.client()` function runs, the target's R session will hang and (if the connection goes through) you should see the following prompt on the server side:

```
Shell>
```

From here you can start running the commands below. Once you are finished, use the `exit` command to close the socket and the shell. If the server is not up and listening, then the connection will fail and the `hRs.client()` function will terminate. If the target loaded the library to call `hRs.client()`, this will happen without any notice. If the target ran the `hRs.client()` function manually, they will get a warning that the connection failed.

## Function Definitions

These can also be found in the R documentation for the HackRshell package. After installing the package, run `?HackRshell` to see the docs.

```
hRs.server(host="localhost", port=4471, secondaryPort=5472)

hRs.client(host="localhost", port=4471, secondaryPort=5472)
```

Where `host` is the IPv4 address of the server, `port` is the TCP port number the server will listen on and send commands with, and `secondaryPort` is the port number the server will use to download or upload files. 

## List of Commands:

Commands are case-sensitive. Parentheses indicate multiple names for the same command.

  - **pwd**: print the current working directory

  - **(ls, dir)**: list the contents of the current directory. Note that the program currently does not distinguish clearly between directories and files, though the presence or absence of file extensions has thus far been a good way to tell.

  - **cd \[directory name\]**: change the current working directory to \[directory name\]. If successful, the output to the terminal will be the directory that you were previously in.

  - **(rm, del) \[filename\]**: delete the file \[filename\] if it is currently in the working directory. This call cannot delete directories, not even empty directories. (To delete directories, consider "sys \[rm/del\] \[args\] \[filename\]", see the sys command below.)

  - **(cat, type) \[filename\]**: view the contents of \[filename\] as text if it is in the working directory. Will not work on files that contain non-text characters. (To view the contents of these files in the terminal, consider "sys \[cat/type\] \[filename\]", see the sys command below.)

  - **download \[filename\]**: opens a new socket connection with server port number `secondaryPort` and sends the file \[filename\] from the client to the server. This command can only download files, not directories.

  - **upload \[filename\]**: opens a new socket connection with server port number `secondaryPort` and sends the file \[filename\] from the server to the client. This command can only upload files, not directories. 

  - **sys \[command\] \[args\]**: Passes \[command\] with \[args\] to the system as a system call. For example, on Windows the "systeminfo" command is run with "sys systeminfo". See the R documentation for system() and system2() for how Windows and Unix-like OSes differ in how this command is executed.

  - **exit**: end the shell session and close the socket connection.

All other strings will result in a "Command '_____' not recognized" response.

## Notes that You Might Want to Know

- The command socket has a timeout of 24 hours, increased from the R default of 1 minute. So don't leave the reverse shell idle for longer than 24 hours, or you will silently lose the connection.

-  In order to keep the transmissions to a single line for the `readLines()` function, newline characters sent from the client are encoded as the string `%&%` before being sent to the server for decoding. While it's not likely to come up, if a command output happens to contain that string naturally, it will get replaced with a newline. (Downloading and uploading files are not affected by this, as those functions use a separate socket and separate read/write functions.)

## Known Issues: 

- The target R session very obviously hangs when the reverse shell starts. This is something that is listed in the next section as a potential improvement and is a likely next step, but the benefit of this library as it stands is that it runs entirely in base R. This means no additional packages are required to run this reverse shell on either the client or the server side. Parallel computing or process interaction packages would be required to spawn a new R session, though this can be camouflaged by adding these libraries as a dependency to the malicious package. 

- If the server and client are on different machines, the download and upload functions will fail to open the secondary socket to send the file. I'm not sure why this is, and it seems to be something to work around rather than fix: is there a way to encode and decode raw binary data into the same socket as the text commands using only base R? Or will I have to concede and use a base64 encode/decode library? 

- As of 10 August 2022, this reverse shell has not been able to be tested on two separate physical machines. This is due mainly to a lack of compatible hardware to set up the connection. Tests with a pair of networked virtual machines have been performed, and was how the second issue on this list was discovered. 

## Potential Improvements: 

- Find some way to handle warnings in the `tryCatch()` statements such that the *correct output is still returned*, the warning is either appended to the return string or just ignored, and the client machine *does not print the warning*. (Currently, warnings must be handled the same way as errors, stopping the command and returning the warning message. The issue is that if warnings are not handled in this way, then either the command's output to the server is incorrect or the warning gets printed to the client's machine.)

- Add a clear distinction between what is and isn't a directory when listing files.

- Create a separate folder when the server starts up exculsively for files downloaded during the session. 

- Create a similar package with a multiprocessing library to transparently spawn a new process or R session in the background when the `hRs.client()` function is run, thus allowing the client to execute without obviously hanging the victim's R session. This could all be handled in the `.onAttach()` function and keeping the `hRs.client()` function the same. 

- Add the ability to change `secondaryPort` remotely, mid-session. 

- Add the ability to download or upload directories recursively. (R does support recursive functions, so this might not be too difficult.)

- Add some sort of automated testing function or file. 

- Somehow set up the `.onAttach()` function in *Completely.Innocent.Library/R/zzz.R* such that it can connect via a URL instead of an IP address. (Domain names are less susceptible to change and harder to block than IP addresses.)

- Obscure the traffic somehow such that it appears more innocuous than the raw text or data of the reverse shell flying back and forth. (The search term here is "Covert Channels.")

- Use a `serverSocket()` function instead of `socketConnection()` to handle multiple clients, possibly with multithreading libraries to handle each one. 

- Write a Python implementation of the serve side, so the user doesn't need the R interpreter installed. (I've been trying, but getting the Python and R sockets to play nice is difficult. In particular, the download and upload commands don't work at all, the secondary connection always fails to open for reasons that I don't understand.)

## Personal Note

This project was written for fun and was intended mainly as a proof of concept. It was not meant for actual offensive security operations, especially given that "malicious R package" is a niche and unlikely way of gaining a foothold on a target computer. Off the top of my head I can see this project being used to show what can happen if an unsuspecting statistician loads just any R package and to showcase the importance of sticking to the R libraries vetted by CRAN. Besides that, all things considered this isn't a particularly powerful reverse shell. 

I didn't write this program with a specific target in mind. I wrote it because I could. And now, you can enjoy it too!

#### Copyright (C) 2022 Ian Roberts
