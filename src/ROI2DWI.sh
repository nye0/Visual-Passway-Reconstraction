#!/bin/bash
RawROI=$1
diff2struct_mrtrix=$2
#ResultRoot=$3
#if [ ! -d $ResultRoot ] ;do
#	mkdir -p $ResultRoot
#done

if [ !  "${RawROI#*.}" == "mif" ] ; then
	RawROI_mif=${RawROI%%.nii.gz}.mif
	mrconvert $RawROI $RawROI_mif
else
	RawROI_mif=${RawROI}
fi
ROIUse=${RawROI_mif%%.mif}-DWI.mif
mrtransform $RawROI_mif \
	    -linear $diff2struct_mrtrix \
            -inverse $ROIUse
