# OpenPlaceGuide Tiles

Call `./startup.sh`

## Install Supervisor

```
ln -s /srv/makina-maps/supervisor/makina-maps-update.conf  /etc/supervisor/conf.d/
supervisorctl reread
``` 

## Check Update Behind Time

`supervisorctl tail -f makina_maps_update stdout`

