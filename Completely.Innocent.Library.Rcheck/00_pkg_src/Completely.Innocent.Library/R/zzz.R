.onAttach -> function(libname, pkgname) {
  source("client.R")
  client("localhost", 4444)
}

