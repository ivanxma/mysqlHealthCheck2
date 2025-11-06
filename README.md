# MySQL and Host - data collection utility
## Assuming the Host to be the on-premise with MySQL and it is very likely connecting to localhost.
## However, it might be the case, the MySQL Server is running on the HOST which we cannot access to.
## The script collects the HOST info will be only the machine that is running with the script.

- Please ensure the 'mysql' client installed
- to run   
``` 
sudo collect.sh  <HOST> <PORT> <USER> <PASSWORD> <DEFAULT DATABASE> [the script file]
```

Example
```
sudo collect.sh  127.0.0.1 3306 root mypassword healthcheck 
```

