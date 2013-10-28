#!/bin/bash

if [ $2 = "yw" ]; then
  file=yw_ecis_uniques.tsv.bz2
  fields=(wld_id year val_usd eci unique_hs)  
  if [ $1 -gt "2000" ]; then
    file=yw_ecis_uniques_growth.tsv.bz2
    fields=(wld_id year val_usd eci unique_hs val_usd_growth_val val_usd_growth_pct)
  fi
  if [ $1 -gt "2004" ]; then
    file=yw_ecis_uniques_growth.tsv.bz2
    fields=(wld_id year val_usd eci unique_hs val_usd_growth_val val_usd_growth_pct val_usd_growth_val_5 val_usd_growth_pct_5)
  fi
fi


if [ $2 = "yp" ]; then
  file=yp_pcis_uniques_rcas.tsv.bz2
  fields=(year hs_id val_usd pci unique_wld rca_wld)
  if [ $1 -gt "2000" ]; then
    file=yp_pcis_uniques_rcas_growth.tsv.bz2
    fields=(hs_id year val_usd pci unique_wld rca_wld val_usd_growth_val val_usd_growth_pct)
  fi
  if [ $1 -gt "2004" ]; then
    file=yp_pcis_uniques_rcas_growth.tsv.bz2
    fields=(hs_id year val_usd pci unique_wld rca_wld val_usd_growth_val val_usd_growth_pct val_usd_growth_val_5 val_usd_growth_pct_5)
  fi
fi


if [ $2 = "yb" ]; then
  file=yb_ecis_uniques.tsv.bz2
  fields=(bra_id year val_usd eci unique_hs unique_wld)
  if [ $1 -gt "2000" ]; then
    file=yb_ecis_uniques_growth.tsv.bz2
    fields=(bra_id year val_usd eci unique_hs unique_wld val_usd_growth_val val_usd_growth_pct)
  fi
  if [ $1 -gt "2004" ]; then
    file=yb_ecis_uniques_growth.tsv.bz2
    fields=(bra_id year val_usd eci unique_hs unique_wld val_usd_growth_val val_usd_growth_pct val_usd_growth_val_5 val_usd_growth_pct_5)
  fi
fi




if [ $2 = "ybp" ]; then
  file=ybp_rcas_dist_opp.tsv.bz2
  fields=(year bra_id hs_id val_usd rca rca_wld distance distance_wld opp_gain opp_gain_wld)
  if [ $1 -gt "2000" ]; then
    file=ybp_rcas_dist_opp_growth.tsv.bz2
    fields=(bra_id hs_id year val_usd rca rca_wld distance distance_wld opp_gain opp_gain_wld val_usd_growth_val val_usd_growth_pct)
  fi
  if [ $1 -gt "2004" ]; then
    file=ybp_rcas_dist_opp_growth.tsv.bz2
    fields=(bra_id hs_id year val_usd rca rca_wld distance distance_wld opp_gain opp_gain_wld val_usd_growth_val val_usd_growth_pct val_usd_growth_val_5 val_usd_growth_pct_5)
  fi
fi


if [ $2 = "ybw" ]; then
  file=ybw.tsv.bz2
  fields=(year bra_id wld_id val_usd)
  if [ $1 -gt "2000" ]; then
    file=ybw_growth.tsv.bz2
    fields=(bra_id wld_id year val_usd val_usd_growth_val val_usd_growth_pct)
  fi
  if [ $1 -gt "2004" ]; then
    file=ybw_growth.tsv.bz2
    fields=(bra_id wld_id year val_usd val_usd_growth_val val_usd_growth_pct val_usd_growth_val_5 val_usd_growth_pct_5)
  fi
fi


if [ $2 = "ypw" ]; then
  file=ypw.tsv.bz2
  fields=(year hs_id wld_id val_usd)
  if [ $1 -gt "2000" ]; then
    file=ypw_growth.tsv.bz2
    fields=(hs_id wld_id year val_usd val_usd_growth_val val_usd_growth_pct)
  fi
  if [ $1 -gt "2004" ]; then
    file=ypw_growth.tsv.bz2
    fields=(hs_id wld_id year val_usd val_usd_growth_val val_usd_growth_pct val_usd_growth_val_5 val_usd_growth_pct_5)
  fi
fi



if [ $2 = "ybpw" ]; then
  file=ybpw.tsv.bz2
  fields=(year bra_id hs_id wld_id val_usd)
  if [ $1 -gt "2000" ]; then
    file=ybpw_growth.tsv.bz2
    fields=(bra_id hs_id wld_id year val_usd val_usd_growth_val val_usd_growth_pct)
  fi
  if [ $1 -gt "2004" ]; then
    file=ybpw_growth.tsv.bz2bz2
    fields=(bra_id hs_id wld_id year val_usd val_usd_growth_val val_usd_growth_pct val_usd_growth_val_5 val_usd_growth_pct_5)
  fi
fi



file=$DATA_DIR"secex/$1/$file"
sql_fields="("
sql_set=""

for field in ${fields[*]}
do
  sql_fields+="@v$field, "
  sql_set+="$field = nullif(@v$field,''), "
done

sql_set=${sql_set%", "}
sql_fields=${sql_fields%", "}
sql_fields+=") "

if [ ! -f $file ]; then
    echo "File not found!"
fi

bunzip2 -k $file
file=${file%".bz2"}
echo $file
mysql -u $DATAVIVA_DB_USER -p -e "load data local infile '$file' into table secex_$2 fields terminated by '\t' lines terminated by '\n' IGNORE 1 LINES $sql_fields SET $sql_set" dataviva --local-infile=1
rm $file