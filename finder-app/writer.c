#include <stdio.h>
#include <syslog.h>

int main (int argc, char * argv[])
{

//args must be 2
if (argc!=3)
{
    syslog(LOG_ERR, "Args must be 2");
    return 1;
}
    

const char *writefile = argv[1];
const char *writestr = argv[2];

//Syslog enable
openlog("WriterLog", 0, LOG_USER);

syslog(LOG_DEBUG, "Writing %s to file %s", writestr, writefile);

FILE *fp = fopen(writefile, "w");
if (fp == NULL) {
    syslog(LOG_ERR, "Error opening file %s", writefile);
    return 1;
}
else
{
    size_t len = fprintf(fp, "%s", writestr);
    if (len < 0) {
        syslog(LOG_ERR, "Error writing %s to file %s", writestr, writefile);
        fclose(fp);
        return 1;
    }

   if (fclose(fp)!= 0) {
        syslog(LOG_ERR, "Error closing  file %s", writefile);
        return 1;
    }

}
closelog();
return 0;



}
