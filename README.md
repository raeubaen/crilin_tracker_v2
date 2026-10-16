```
scp rgargiul@lxplus.cern.ch:/afs/cern.ch/work/r/rgargiul/tracker_2/tracker_logcentroid_w*_percent.root data/
```

```
for i in data/*; do w=$(echo $i | awk -F '_' '{print $3}'); source calibrate.sh $i $w | grep "alias: " | sed 's/alias: //g' > aliases_$w.txt; done
```

```
hadd -f y_center.root *_y_center*
hadd -f x_center.root *_x_center*
```

```
source compare.sh y_center.root y | grep "sigma: " > sigma_y.txt
source compare.sh x_center.root x | grep "sigma: " > sigma_x.txt
```

```
source scan_reso.sh data/tracker_logcentroid_w300_percent.root 
```

# crilin_tracker_v2
