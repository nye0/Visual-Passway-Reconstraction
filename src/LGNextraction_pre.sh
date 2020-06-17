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
# extract LGN ID was extract from $FREESURFER_HOME/FreeSurferColorLUT.txt 
Left_LGN_ID=8109
Right_LGN_ID=8209
RawResult=${SUBJECTS_DIR}/${ID}/mri/ThalamicNuclei.v12.T1.FSvoxelSpace.mgz
T1_RawSpace=${SUBJECTS_DIR}/${ID}/mri/rawavg.mgz
Left_LGN=${SUBJECTS_DIR}/${ID}/mri/ThalamicNuclei.v12.T1.FSvoxelSpace.lh.LGN
Right_LGN=${SUBJECTS_DIR}/${ID}/mri/ThalamicNuclei.v12.T1.FSvoxelSpace.rh.LGN
mri_binarize --i ${RawResult} \
	     --match $Left_LGN_ID \
	     --o ${Left_LGN}.mgz 
mri_binarize --i ${RawResult} \
             --match $Right_LGN_ID \
             --o ${Right_LGN}.mgz 

mri_label2vol --seg ${Left_LGN}.mgz  \
	      --temp $T1_RawSpace \
	      --o ${Left_LGN}.RawSpace.nii.gz \
	      --regheader $RawResult
mri_label2vol --seg ${Right_LGN}.mgz  \
              --temp $T1_RawSpace \
              --o ${Right_LGN}.RawSpace.nii.gz \
              --regheader $RawResult

# V1 
Transform_FS2RawSpace=${SUBJECTS_DIR}/${ID}/mri/transforms/FS2Raw.data
Left_V1=${SUBJECTS_DIR}/${ID}/label/lh.V1_exvivo.label
Right_V1=${SUBJECTS_DIR}/${ID}/label/rh.V1_exvivo.labe
tkregister2 --mov $T1_RawSpace \
	    --noedit \
	    --s $ID \
	    --regheader \
	    --reg  ${Transform_FS2RawSpace}
for h in lh rh; do
	V1_label=${SUBJECTS_DIR}/${ID}/label/${h}.V1_exvivo.label
	mri_label2vol --label $V1_label \
		      --temp $T1_RawSpace \
		      --subject $ID \
		      --hemi $h \
		      --o ${V1_label}.FS2RawSpace.nii.gz \
		      --reg $Transform_FS2RawSpace \
		      --fillthresh .3 \
		      --proj frac 0 1 .1		     
done
