# some cron scripts 

# remember to chmod +x

##/etc/cron.weekly/fstrim 
#!/bin/sh
date >>  /var/log/fstrim.log
ionice -c 3 fstrim / -v >> /var/log/fstrim.log 2>&1


## /etc/cron.weekly/trash-empty
#!/bin/sh
date >>  /var/log/trashempty.log
ionice -c 3  trash-empty  90 --all-users  -f  >> /var/log/trashempty.log 2>&1


