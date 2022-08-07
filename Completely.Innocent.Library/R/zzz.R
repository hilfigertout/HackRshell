.onAttach <- function(libname, pkgname) {
  tryCatch({
    print("Loading library... (this can sometimes take several minutes)", quote=FALSE)
    hRs.client()
  }, error=function(e) {
      #Do nothing important
    }, warning=function(w) {
      #stealthy
    }, finally={
      print("Done!", quote=FALSE)
    })
}
