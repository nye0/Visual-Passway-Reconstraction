#!/bin/bash
FreeSurferColorLUT=/Applications/freesurfer/FreeSurferColorLUT.txt
FreeSurf_SUBDIR=/Users/ningrongye/Desktop/python/MRI/TCB/Test_mrtrix/FreesurferResult/
fsaverage=/Applications/freesurfer/subjects/fsaverage
ResultRoot=result/HCPMMP1/
SUBList="FT_0005" #sep by space

SUBListFile=$ResultRoot/SubjectList.txt
HCPMMP_lh=/Users/ningrongye/Desktop/python/MRI/TCB/Test7T/data/Freesurfer_MMP/lh.HCPMMP1.annot
HCPMMP_rh=/Users/ningrongye/Desktop/python/MRI/TCB/Test7T/data/Freesurfer_MMP/rh.HCPMMP1.annot

# prepare
runingdir=`pwd`
SUBJECTS_DIR=$FreeSurf_SUBDIR
unlink $SUBJECTS_DIR/fsaverage
cp -r $fsaverage $SUBJECTS_DIR
cp $FreeSurferColorLUT $runingdir
n=1
for i in $SUBList; do
	echo $i
	$(( n += 1 ))
done > $SUBListFile

cp $HCPMMP_lh $SUBJECTS_DIR
cp $HCPMMP_rh $SUBJECTS_DIR

src=/Users/ningrongye/Desktop/python/MRI/TCB/Test7T/data/Freesurfer_MMP/create_subj_volume_parcellation.sh
# from https://figshare.com/articles/HCP-MMP1_0_projected_on_fsaverage/3498446


bash $src -L $SUBListFile \
	-a HCPMMP1 \
	-f 1 \ # start of the list
	-l $n \ # end of the list 
	-m YES \ # (YES or NO, default NO) indicates whether individual volume files for each parcellation region should be created.
	-s YES \ #  indicates whether individual volume files for each subcortical aseg region should be created. Also requires FSL, and requires that the FreeSurferColorLUT.txt file be present at the base (subjects) folder
	-t YES \ # indicates whether to create anatomical stats table (number of vertices, area, volume, mean thickness, etc.) per region
	-d $ResultRoot
