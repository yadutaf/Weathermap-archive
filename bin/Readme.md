# HOWTO add/remove a site from the archiving process

The main script here is 'archive.sh'. The only parameter to tweak in this file is
'BASEDIR'. This variable controls the place where the archived maps will be stored
and must be writable by the user executing the script and readable by the user executing
the server application.

This script will look for sub-scripts in 'archive.d/' subfolder. Only executable scripts
will be taken into account. Files do not need to end with ".sh" but it is highly recommended
to keep things clean.

## Manage scripts

To enable a script just add the execute permission on it:

  $ chmod +x archived.d/script-to-enable.sh

To disable a script just remove the execute permission on it:
  
  $ chmod -x archived.d/script-to-disable.sh

## Roll you own backup

### Weathermap updated every 5 mins

Most weathermaps are updated every 5 mins. This is why we provide an helper structure
for this case. You may add a custom rule the 5min.d/ subfolder. Main script expects an output
of the form :

```
mapname;http://domain.tld/path/to/weathermap.png
```

The script basename (without the extension), will be used as the Groupname.

### General cases

If you map requires a special action like authentication, you are welcome
to create a custom script in archive.d folder. The target folder basepath 
will be provided as "$1". As soon as your ascript gets the 'x' bit, it will be
launched by the main script. See 5min.sh for an example.
