#!/bin/bash
SUBJECTS_DIR=/media/oxygen/y2/202002/git/freesurfer_LGNextraction/result/
Raw=./data/YQ_T1_0006
T1_f1=`ls $Raw|head -1`
T2=./data/YQ_T2_0007
T2_f1=`ls  $T2|head -1`
ID=YQ_0006
recon-all -sd $SUBJECTS_DIR \
	  -subjid $ID \
	  -cm \
	  -all \
	  -mprage \
	  -qcache \
	  -i $Raw/$T1_f1 \
	  -T2 $T2/$T2_f1 -T2pial
segmentThalamicNuclei.sh YQ_0006
freeview -v ${SUBJECTS_DIR}/${ID}/mri/nu.mgz \
	 -v ${SUBJECTS_DIR}/${ID}/mri/ThalamicNuclei.v12.T1.mgz:colormap=lut &
