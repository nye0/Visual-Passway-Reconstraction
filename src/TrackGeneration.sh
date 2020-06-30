#!/bin/bash
tt5=$1
seed=$2
include=$3
wmfod_norm=$4
ResultRoot=$5
TrackName=$6
maxlength=$7

select=5000
ReduceF=10
cutoff=0.2
#refine="-cutoff 0.2 -maxlength 100" # 100 for LGN2V1; 50 for optialChiasm to LGN

get_batch_options(){
        local arguments=("$@")
        local index=0
        local numArgs=${#arguments[@]}
        local argument

        while [ ${index} -lt ${numArgs} ]; do
                argument=${arguments[index]}
                case ${argument} in
                        --act=*)
                                tt5=${argument#*=}
                                index=$(( index + 1 ))
                                ;;
                        --wmfod_norm=*)
                                wmfod_norm=${argument#*=}
                                index=$(( index + 1 ))
                                ;;
                        --seed_roi=*)
                                # 
                                seed=${argument#*=}
                                index=$(( index + 1 ))
                                ;;
                        --include_roi=*)
                                include=${argument#*=}
                                index=$(( index + 1 ))
                                ;;
			--TrackName=*)
				TrackName=${argument#*=}
                                index=$(( index + 1 ))
                                ;;
			--TrackMaxLength=*)
				maxlength=${argument#*=}
                                index=$(( index + 1 ))
                                ;;
			--ResultRoot=*)
				ResultRoot==${argument#*=}
                                index=$(( index + 1 ))
                                ;;
                        *)

                echo ""
                echo "ERROR: Unrecognized Option: ${argument}"
                echo ""
                exit 1
                ;;
        esac
    done
}
get_batch_options "$@"
# check the input
#----------------------------------------------------------
if [ -n "${tt5}" ]; then
        if [ -e "${tt5}" ]; then
                echo tissue mask: $tt5
        else
                echo tissue mask Do not exist!
                exit
        fi
else
        echo Please set act!
        exit
fi
if [ -n "${wmfod_norm}" ]; then
        if [ -e "${wmfod_norm}" ]; then
                echo wmfod_norm: $wmfod_norm
        else
                echo wmfod_norm Do not exist!
                exit
        fi
else
        echo Please set wmfod_norm!
        exit
fi

if [ -n "${seed_roi}" ]; then
        if [ -e "${seed_roi}" ]; then
                echo seed_roi: $seed_roi
        else
                echo seed roi Do not exist!
                exit
        fi
else
        echo Please set seed roi!
        exit
fi

if [ -n "${include_roi}" ]; then
        if [ -e "${include_roi}" ]; then
                echo include_roi: $include_roi
        else
                echo include roi Do not exist!
                exit
        fi
else
        echo Please set include roi!
        exit
fi

if [ -n "${ResultRoot}" ]; then
        echo ResultRoot: $ResultRoot
        if [ ! -d "${ResultRoot}" ]; then
                mkdir -p ${ResultRoot}
        fi
else
        echo Please Set ResultRoot!
        exit
fi
#----------------------------------------------------------


track=$ResultRoot/track_${TrackName}-S${select}.C2.MaxL${maxlength}.tck
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


