\name{client}
\alias{client}
%- Also NEED an '\alias' for EACH other topic documented here.
\title{
A client-side reverse shell function.
}
\description{
This function connects back to a remote host specified by the host and port arguments. If the server is listening on the remote host at the correct port, then this function will make the R session listen for commands entered from the server and will attempt to execute them. See the notes section for a list of valid commands.
}
\usage{
client(host, port)
}
%- maybe also 'usage' for other objects documented here.
\arguments{
  \item{host} {
    The IPv4 address of the remote server, as a string. Written in the standard "dotted decimal" notation, e.g. "192.168.0.1". Can also be "localhost".
  }
  \item{port}{
    The TCP port number of the listening process on the remote server, as an integer.
  }
}
\details{
%%  ~~ If necessary, more details than the description above ~~
}
\value{
This function does not return any value.
}
\references{
%% ~put references to the literature/web site here ~
}
\author{
Ian Roberts
}
\note{
List of Commands:

  pwd: print the current working directory

  (ls, dir): list the contents of the current directory

  cd [directory name]: change the current working directory to [directory name]

  (rm, del) [filename]: delete the file [filename] if it is currently in the working directory, recursively if it's a directory. Equivalent to "rm -rf".
}

%% ~Make other sections like Warning with \section{Warning }{....} ~

\seealso{
%% ~~objects to See Also as \code{\link{help}}, ~~~
}
\examples{
##---- Should be DIRECTLY executable !! ----
##-- ==>  Define data, use random,
##--	or do  help(data=index)  for the standard data sets.

## The function is currently defined as
function (x)
{
  }
}
% Add one or more standard keywords, see file 'KEYWORDS' in the
% R documentation directory (show via RShowDoc("KEYWORDS")):
% \keyword{ ~kwd1 }
% \keyword{ ~kwd2 }
% Use only one keyword per line.
% For non-standard keywords, use \concept instead of \keyword:
% \concept{ ~cpt1 }
% \concept{ ~cpt2 }
% Use only one concept per line.
