#http://www.deploymentresearch.com/Research/tabid/62/EntryId/143/Automatic-Maintenance-in-Windows-Server-2012-R2-is-EVIL.aspx
psexec -accepteula -s schtasks /change /tn "\Microsoft\Windows\TaskScheduler\Maintenance Configurator" /DISABLE
#Disable all other tasks in “Task Scheduler Library\Microsoft\Windows\TaskScheduler”.
