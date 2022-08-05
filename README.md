# HackRshell

## The R Reverse Shell 

This project implements a basic reverse shell in R. When a target runs the `client()` function in this package (either directly or on attachment of the package), their R session will attempt to reach out to a server running the `server()` function in *server.R*. If the server is listening, the user behind the server will then be able to send commands to traverse the target's directory, upload or exfiltrate files, and make system calls. A full list of commands can be found below.

This reverse shell is written entirely in base R, with no additional packages needing installed. In addition, the *Completely.Innocent.Library* package is a custom-built malicious package designed exclusively to execute the `client()` function when the package is attached. This is to demonstrate how a target could unsuspectingly open the connection. It is not necessary to install this library to run the reverse shell, see the **Usage** section below. 

## Contents:

 - **README.md**

 - **LICENSE** - this software is under the Lesser GNU public license (LGPL). See the file for deatils.

 - **server.R** - This file contains the `server()` function that the user runs to listen for reverse shell connections.

 - **client.R** - this file contains the `client()` function that the target runs to start the reverse shell session. While one can load the function and call it via the R terminal, running `source("./client.R")` will do the same thing, assuming that the working directory contains client.R.

 - **Completely.Innocent.Library** - this folder contains the R project and all the data for a custom R package called "Completely.Innocent.Library". This package contains a *client.R* file, identical to the one in the top level of the repository except for the function call at the end. This package was built to execute the `client()` function when the target installs the package and calls `library("Completely.Innocent.Library")`. You can see the code for this autorun in *Completely.Innocent.Library/R/zzz.R*.

 - **Completely.Innocent.Library_0.1.0.tar.gz** - a tarball of the *Completely.Innocent.Library* package for installation. You will need the rtools package to install this, which you can find [here](https://cran.r-project.org/bin/windows/Rtools/).

## Usage: 

To run this program, you will need to have R installed. To start the server, simply open an R session and call the `server()` function located in *server.R*. This will start the server listening. From there it's simply a matter of waiting for someone to run the `client()` function with the correct address and port.

Since it's safe to assume you are probably demonstrating this on your own machine, you can create a new R session and run the function yourself. You can either run the function in *client.R*, or you can attach the malicious package with the command `library(Completely.Innocent.Library)`. This will automatically start the `client()` function with the parameters baked into the library, so if you want to change the ip address or ports that the server is on from the defaults, you will need to rebuild the library after every change. 

Once the `client()` function runs, the target's R session will hang and (if the connection goes through) you should see the following prompt on the server side:

```
Shell>
```

From here you can start running the commands below. Once you are finished, use the `exit` command to close the socket and the shell. If the server is not up and listening, then the connection will fail and the `client()` function will terminate. If the target loaded the library to call `client()`, this will happen without any notice. If the target ran the `client()` function manually, they will get a warning that the connection failed.

## List of Commands:

Commands are case-sensitive. Parentheses indicate multiple names for the same command.

  - **pwd**: print the current working directory

  - **(ls, dir)**: list the contents of the current directory. Note that the program currently does not distinguish clearly between directories and files, though the presence or absence of file extensions has thus far been a good way to tell.

  - **cd \[directory name\]**: change the current working directory to \[directory name\].

  - **(rm, del) \[filename\]**: delete the file \[filename\] if it is currently in the working directory. This call cannot delete directories, not even empty directories. (To delete directories, consider "sys \[rm/del\] \[args\] \[filename\], see the sys command below.)

  - **(cat, type) \[filename\]**: view the contents of \[filename\] as text if it is in the working directory. Will not work on files that contain non-text characters. (To view the contents of these files in the terminal, consider "sys \[cat/type\] \[filename\]", see the sys command below.)

  - **download \[filename\]**: opens a new socket connection with server port number secondaryPort and sends the file \[filename\] from the client to the server. This file will not be available to edit or delete until after the R session the server is running on terminates.

  - **upload \[filename\]**: opens a new socket connection with server port number secondaryPort and sends the file \[filename\] from the server to the client. This file will not be available to edit or delete until after the R session the client is running on terminates.

  - **exit**: end the shell session and close the socket connection.

  - **sys \[command\] \[args\]**: Passes \[command\] with \[args\] to the system as a system call. For example, on Windows the "systeminfo" command is run with "sys systeminfo". See the R documentation for system() and system2() for how Windows and Unix-like OSes differ in how this command is executed.

  All other strings will result in a "Command '_____' not recognized" response.

## Notes that You Might Want to Know

- The command socket has a timeout of 5 minutes, increased from the R default of 1 minute. If one or both sockets is waiting on communication for 5 minutes, they will skip past that communication with a null value. There are some safeguards in place to prevent this from causing a crash, and in general it should be safe to let the program idle for a while, but you may see a few null reads pop up on your screen. 

-  In order to keep the transmissions to a single line for the `readLines()` function, newline characters sent from the client are encoded as the string `%&%` before being sent to the server for decoding. While it's not likely to come up, if a command output happens to contain that string naturally, it will get replaced with a newline. (Downloading and uploading files are not affected by this, as those functions use a separate socket and separate read/write functions.)

## Known Issues:

- If you upload or download a file using this shell, that file will not be able to be edited while the R session is active as it is considered still locked by the R session. This also prevents you from deleting a file after uploading or downloading it. In addition, for a file uploaded to the client, the data inside will not appear until the R session terminates, meaning that at present it is not possible to upload an additional payload and run it.

- R does not appear to close any connections besides the main one after use, despite this code calling the `close()` function on all of them. This means that a warning will appear to the target after the shell terminates for every **upload**, **download**, or **(cat/type)** command called during the session. This isn't particularly stealthy, but these messages only seem to appear after the session terminates, which may be too late for the target to take any meaningful action. 

- Sometimes clients just stop responding after trying a particularly sensitive command, especially a failed system call. I've tried to iron out as many cases as possible, but at the end of the day, most computers' environments are not friendly to reverse shells. 

- The target R session very obviously hangs when the reverse shell starts. This is something that listed in the next section as a potential improvement and is a likely next step, but the benefit of this library as it stands is that it runs entirely in base R. This means no additional packages are required to run this reverse shell on either the client or the server side. Parallel computing or process interaction packages would be required to spawn a new R session, though this can be camouflaged by adding these libraries as a dependency to the malicious package. 

- As of 4 August 2022, this shell has not been able to be tested on two separate machines, and has only been tested with the localhost connection. This has been due mainly to a lack of compatible hardware. A test with a pair of networked virtual machines is likely in the near future, assuming I maintain enough interest in this project. 

## Potential Improvements: 

- Find some way to handle warnings in the tryCatch() statements such that the *correct output is still returned*, the warning is either appended to the return string or just ignored, and the client machine *does not print the warning*. 

- Add a clear distinction between what is and isn't a directory when listing files.

- Create a separate folder when the server starts up exculsively for files downloaded during the session. 

- Refactor the server-side code so that the client() function isn't just one giant function, but instead calls smaller functions for each of its tasks. (Client's already done, now for the server.)

- Create a similar package with a multiprocessing library to transparently spawn a new process or R session in the background when the client() function si run, thus allowing the client to execute without obviously hanging the victim's R session. This could all be handled in the .onAttach() function and keeping the client() function the same. 

- Add the ability to download or upload directories recursively.

- Somehow set up the .onAttach() function in zzz.R such that it can connect via a URL instead of an IP address. (Domain names are harder to change and harder to block than IP addresses.)

- Obscure the traffic somehow such that it appears more innocuous than the text or data flying back and forth. (The search term here is "Covert Channels.")

- Use a serverSocket() function instead of socketConnection() to handle multiple clients, possibly with multithreading libraries to handle each one. 

## Personal Note

This project was written for fun and is intended mainly as a proof of concept. It was not meant for actual offensive security operations, especially given that "malicious R package" is a niche and unlikely way of gaining a foothold on a target computer. Off the top of my head I can see this project being used to show what can happen if an unsuspecting statistician loads just any R package and to showcase the importance of sticking to the R libraries vetted by CRAN. Besides that, all things considered this isn't a particularly powerful reverse shell. 
