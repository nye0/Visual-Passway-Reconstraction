#!/bin/bash
tt5=$1
seed=$2
include=$3
wmfod_norm=$4
ResultRoot=$5
TrackName=$6
select=5000
ReduceF=10

refine="-cutoff 0.2 -maxlength 100" # 100 for LGN2V1; 50 for optialChiasm to LGN
mkdir -p $ResultRoot
track=$ResultRoot/track_${TrackName}-S.${select}.tck
track_reduced=${track%%.tck}-red.${ReduceF}.tck
tckgen  -act $tt5 \
	-backtrack \
	-seed_image $seed \
	-include $include \
	-select $select \
	$wmfod_norm $track \
	$refine


tcksift -act $tt5 \
	-term_number $(( select/ReduceF )) \
	$track $wmfod_norm \
	$track_reduced


