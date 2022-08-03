server <- function(host, port, secondaryPort=5472) {
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
            signalCondition(simpleError("Download Aborted"))
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
            writeBin(fileData, outFile, size=1)
          }, error=function(e){
            print(paste("Error writing received data: ", e$message))
          }, finally=function() {
            close(outFile)
          })
        }
      }

      else if (firstWord == "upload") {

      }
    }

    if (!exiting) {
      fromClient <- readLines(socket, 1)
      fromClient <- gsub("%&%", "\n", fixed=TRUE, fromClient)
    }
  }
  close(socket)
  close(fileSocket)
  print("Sockets closed")
}

server("localhost", 4444)

