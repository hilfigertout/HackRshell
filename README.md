#R Reverse Shell



Known Issues:

- If you upload or download a file using this shell with RStudio, that file will not be able to be edited while Rstudio is active as it is considered still locked by the R session. This also prevents you from deleting or executing a file after uploading it. In addition, for a file uploaded to the client, the data inside will not appear until the R session terminates, meaning that at present it is not possible to upload more payloads and run them. 

Potential Improvements: 

- Add the ability to download or upload directories recursively.

- Add a clear distinction between what is and isn't a directory when listing files.

- Refactor the code so that the Client function isn't just one giant function, but instead calls smaller functions for each of its tasks. (Good luck.)

- Create a similar package with a multiprocessing library to transparently spawn a new process or R session in the background, thus allowing the client to execute without obviously hanging the victim's R session.

- Create a separate folder when the server starts up exculsively for files downloaded during the session. 

- Somehow set up the .onAttach() function in zzz.R such that it can connect via a URL instead of an IP address. (Domain names are harder to change and harder to block than IP addresses.)

- Obscure the traffic somehow such that it appears more innocuous than the text or data flying back and forth. (The search term here is "Covert Channels.")