#!/bin/bash
RawROI=$1
diff2struct_mrtrix=$2
ResultRoot=$3
if [ ! -d $ResultRoot ] ; then
	mkdir -p $ResultRoot
fi

if [ !  "${RawROI#*.}" == "mif" ] ; then
	RawROI_mif=${RawROI%%.nii.gz}.mif
	if [ ! -e $RawROI_mif ] ; then
		mrconvert $RawROI $RawROI_mif
	fi
else
	RawROI_mif=${RawROI}
fi
ROIName=`basename $RawROI_mif`
ROIUse=${ResultRoot}/${ROIName%%.mif}-DWI.mif

mrtransform $RawROI_mif \
	    -linear $diff2struct_mrtrix \
            -inverse $ROIUse
