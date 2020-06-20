#!/bin/bash
RawROI=$1
diff2struct_mrtrix=$2
#ResultRoot=$3
#if [ ! -d $ResultRoot ] ;do
#	mkdir -p $ResultRoot
#done

RawROI_mif=${RawROI%%.nii.gz}.mif
ROIUse=${RawROI_mif%%.mif}-DWI.mif
mrconvert $RawROI ${RawROI%%.nii.gz}.mif
mrtransform $RawROI_mif \
	    -linear $diff2struct_mrtrix \
            -inverse $ROIUse
