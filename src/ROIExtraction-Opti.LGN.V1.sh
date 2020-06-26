#!/bin/bash
#SUBJECTS_DIR=/media/oxygen/y2/202002/git/freesurfer_LGNextraction/result/
#Raw=./data/YQ_T1_0006
#T1_f1=`ls $Raw|head -1`
#T2=./data/YQ_T2_0007
#T2_f1=`ls  $T2|head -1`
#ID=YQ_0006
TemplateImagePath=$FSLDIR/data/standard/MNI152_T1_1mm.nii.gz
# OpticalNerve_ROI should be draw on the template image.
#OpticalNerve_ROIRoot=
#./data/lh.OptialNever.MNI152_1mm.nii.gz
get_batch_options(){
        local arguments=("$@")
        local index=0
        local numArgs=${#arguments[@]}
        local argument

        while [ ${index} -lt ${numArgs} ]; do
                argument=${arguments[index]}
                case ${argument} in
                        --SubjectID=*)
                                SubjectID=${argument#*=}
                                index=$(( index + 1 ))
                                ;;
                        --T1Image=*)
                                T1Image=${argument#*=}
                                index=$(( index + 1 ))
                                ;;
                        --T2Image=*)
                                # 
                                T2Image=${argument#*=}
                                index=$(( index + 1 ))
                                ;;
                        --ResultRoot=*)
                                ResultRoot=${argument#*=}
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
if [ -n "${SubjectID}" ]; then
	echo SubjectID: $SubjectID
else
	echo Please set SubjectID!
	exit
fi
if [ -n "${T1Image}" ]; then
        if [ -e "${T1Image}" ]; then
                echo T1Image: $T1Image
        else
                echo T1Image Do not exist!
                exit
        fi
else
        echo Please set T1Image!
        exit
fi
if [ -n "${T2Image}" ]; then
        if [ -e "${T2Image}" ]; then
                echo T2Image: $T2Image
        else
                echo T2Image Do not exist!
                exit
        fi
else
        echo Please set T2Image!
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

SUBJECTS_DIR=${ResultRoot}/freesurfer/
T1_f1=`ls $T1Image|head -1`
T2_f1=`ls  $T2Image|head -1`
MaskUseRoot=${ResultRoot}/ROIUse/
AntsRegRoot=${ResultRoot}/AntsReg/

Left_LGN_ID=8109
Right_LGN_ID=8209
FSRoot=${SUBJECTS_DIR}/${SubjectID}/
FS_ThalamicNucleiSeg=$FSRoot/mri/ThalamicNuclei.v12.T1.FSvoxelSpace.mgz
FS_T1Orig=$FSRoot/mri/orig/001.mgz
Left_LGN=$FSRoot/mri/ThalamicNuclei.v12.T1.FSvoxelSpace.lh.LGN
Right_LGN=$FSRoot/mri/ThalamicNuclei.v12.T1.FSvoxelSpace.rh.LGN

Left_LGNUse=$MaskUseRoot/T1Orig-lh.LGN.nii.gz
Right_LGNUse=$MaskUseRoot/T1Orig-rh.LGN.nii.gz


Transform_FS2T1Orig=$FSRoot/mri/transforms/FS2T1Orig.data

mkdir -p $MaskUseRoot $SUBJECTS_DIR $AntsRegRoot
recon-all -sd $SUBJECTS_DIR \
	  -subjid $SubjectID \
	  -cm \
	  -all \
	  -mprage \
	  -qcache \
	  -i $T1Image/$T1_f1 \
	  -T2 $T2Image/$T2_f1 -T2pial
segmentThalamicNuclei.sh $SubjectID
#freeview -v ${SUBJECTS_DIR}/${SubjectID}/mri/nu.mgz \
#	 -v ${SUBJECTS_DIR}/${SubjectID}/mri/ThalamicNuclei.v12.T1.mgz:colormap=lut &
# extract LGN ID was extract from $FREESURFER_HOME/FreeSurferColorLUT.txt 
mri_binarize --i $FS_ThalamicNucleiSeg \
	     --match $Left_LGN_ID \
	     --o ${Left_LGN}.mgz 
mri_binarize --i $FS_ThalamicNucleiSeg \
             --match $Right_LGN_ID \
             --o ${Right_LGN}.mgz 

mri_label2vol --seg ${Left_LGN}.mgz  \
	      --temp $FS_T1Orig \
	      --o ${Left_LGNUse} \
	      --regheader $FS_ThalamicNucleiSeg
mri_label2vol --seg ${Right_LGN}.mgz  \
	      --temp $FS_T1Orig \
              --o ${Right_LGNUse} \
              --regheader $FS_ThalamicNucleiSeg

# V1 
tkregister2 --mov $FS_T1Orig \
	    --noedit \
	    --s $SubjectID \
	    --regheader \
	    --reg  ${Transform_FS2T1Orig}
for h in lh rh; do
	V1_label=$FSRoot/label/${h}.V1_exvivo.label
	V1Use=$MaskUseRoot/T1Orig-${h}.V1_exvivo.nii.gz
	# based on http://surfer.nmr.mgh.harvard.edu/fswiki/mri_label2vol , example 2
	mri_label2vol --label $V1_label \
		      --temp $FS_T1Orig \
		      --subject $SubjectID \
		      --hemi $h \
		      --o ${V1Use} \
		      --reg $Transform_FS2T1Orig \
		      --fillthresh .3 \
		      --proj frac 0 1 .1		     
done

# optical nerve
TargetImage=$FS_T1Orig
prefix=Template2T1Orig
antsRegistrationSyN.sh  -d 3 \
                        -f $TargetImage \
                        -m $TemplateImagePath \
                        -t s  \
                        -o $AntsRegRoot/$prefix
AffineTrans=$AntsRegRoot/${prefix}0GenericAffine.mat
DiformedTrans=$AntsRegRoot/${prefix}1Warp.nii.gz
DiformedTrans_inverse=$AntsRegRoot/${prefix}1InverseWarp.nii.gz

for h in lh rh; do
	OpticalNerve_ROI=./data/${h}.OptialNerve.MNI152_1mm.nii.gz
	ROI2Target=$MaskUseRoot/T1Orig-${h}.OptialNerve.MNI152_1mm.nii.gz
	ROI2Target_bin=${ROI2Target%%.nii.gz}-bin.nii.gz
	antsApplyTransforms -d 3 \
                            -i $TemplateROI \
                            -o $ROI2Target \
                            -r $TargetImagePath \
                            -t $DiformedTrans \
                            -t $AffineTrans
	
	fslmaths $ROI2Target \
        	-thr 0  \
	        -bin $ROI2Target_bin
done

