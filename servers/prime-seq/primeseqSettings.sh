#PRIME-seq:

MAJOR=20
MINOR_FULL="3"
MINOR_SHORT=3
ARTIFACT=LabKey${MAJOR}.${MINOR_FULL}Beta

LKENV=$(grep ^EnvironmentFile /etc/systemd/system/labkey.service | cut -d = -f2 | sed 's/ //g')
TOMCAT_HOME=$(grep ^CATALINA_HOME $LKENV | cut -d= -f2 | sed 's/ //g')

TEAMCITY_USERNAME=bbimber

LABKEY_HOME=/usr/local/labkey
LABKEY_USER=labkey