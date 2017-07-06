The dockerfile needs the ojdbc7.jar to be in the same directory. It is available for download from Oracle's site in order to configure the Payara (Glassfish) server.
The command to build the image, after entering this directory, is "docker build -t insurit/payara-confdb ."

Also it is included the source sql file to create the necessary database artifacts (plsql dialect). The way it is used then from procedures inside database is described in the presentation. 