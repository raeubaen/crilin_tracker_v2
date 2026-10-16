a=$(cat aliases_w300.txt)

root $1 << EOF
   $a
  .L ~/Downloads/dcb.cxx
  .L scan_dcb.C
  scan_dcb(recoTree, "on_lxplus/scan_positions.csv");

EOF
