#!/bin/bash
tt5=$1
seed=$2
include=$3
wmfod_norm=$4
ResultRoot=$5
track_10mio=$ResultRoot/track_10mio.tck
tckgen  -act $tt5 \
	-backtrack \
	-seed_image $seed \
	-include $include \
	-select 1000000 \
	$wmfod_norm $track_10mio


