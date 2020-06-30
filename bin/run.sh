#!/bin/bash
RawDWI_AP=data/YQ_DTI_AP/
PE=AP
RPE=all
RPE_Image=data/YQ_DTI_PA/
DTIpre_ResultRoot=./result/DTIpre/

T1Image=data/YQ_T1_0006/
T2Image=data/YQ_T2_0007/
SubjectID=YQ_0006
ROIExtraction_ResultRoot=/media/oxygen/y2/202002/git/Visual-Passway-Reconstraction/result/ROIExtraction/
SUBJECTS_DIR=$ROIExtraction_ResultRoot/freesurfer/
ROIUseRoot=$ROIExtraction_ResultRoot/ROIUse/

FS_T1Orig=$SUBJECTS_DIR/$SubjectID/mri/orig/001.nii.gz
PreprocessedDTI=$DTIpre_ResultRoot/DWI-raw-den-unr-mdc-unbiased.mif
BrainMask=$DTIpre_ResultRoot/DWI-raw-den-unr-mdc-unbiased-unbrain_mask.mif
FiberEstimation_ResultRoot=result/FiberEstimation/


src/DTIpre.sh  --RawImage=data/YQ_DTI_AP/ \
	       --RawImage_PE=AP \
	       --RPE=all \
	       --RPE_Image=data/YQ_DTI_PA/ \
	       --ResultRoot=./result/DTIpre/ 
src/ROIExtraction-Opti.V1.LGN.sh --SubjectID=YQ_0006 \
			    --T1Image=data/YQ_T1_0006/ \
			    --T2Image=data/YQ_T2_0007/ \
			    --ResultRoot=/media/oxygen/y2/202002/git/Visual-Passway-Reconstraction/result/ROIExtraction/

src/FiberEstimation.sh --PreprocessedImage=result/DTIpre/DWI-raw-den-unr-mdc-unbiased.mif \
		       --T1Image=../freesurfer_LGNextraction/result/YQ_0006/mri/orig/001.nii.gz \
		       --BrainMask=result/DTIpre/DWI-raw-den-unr-mdc-unbiased-unbrain_mask.mif \
		       --ResultRoot=result/FiberEstimation/
# build fiber
#T1 ROI to DWI
DWI2T1=$FiberEstimation_ResultRoot/diff2struct-mrtrix.txt
for h in lh rh; do
	LGN=$ROIUseRoot/T1Orig-${h}.LGN.nii.gz
	V1=$ROIUseRoot/T1Orig-${h}.V1_exvivo.nii.gz
	OpticalNerve=$ROIUseRoot/T1Orig-${h}.OptialNerve.nii.gz
	for roi in $LGN $V1 $OpticalNerve; do
		src/ROI2DWI.sh $roi $DWI2ROI
	done
	LGNUse=${LGN%%.nii.gz}-DWI.mif
	V1Use=${V1%%.nii.gz}-DWI.mif
	OpticalNerveUse=${OpticalNerve%%.nii.gz}-DWI.mif
# track Optial Nerve to LGN
	tt5=$FiberEstimation_ResultRoot/5tt-coreg.mif
	wm_fodnorm=$FiberEstimation_ResultRoot/fod_wm-norm.mif
	TrackMaxLength_Op2LGN=50
	TrackMaxLength_LGN2V1=100
	TrackName_Op2LGN=${h}.OpticalNerve2LGN
	TrackName_LGN2V1=${h}.LGN2V1
	TrackGeneration_ResultRoot=result/TrackGeneration/
	src/TrackGeneration.sh --act $tt5 \
	       	               --seed_roi $OpticalNerveUse \
			       --include_roi $LGNUse \
			       --wm_fodnorm $wm_fodnorm \
			       --ResultRoot $TrackGeneration_ResultRoot \
			       --TrackName $TrackName_Op2LGN \
			       --TrackMaxLength $TrackMaxLength_Op2LGN
	src/TrackGeneration.sh --act $tt5 \
			       --seed_roi $LGNUse \
			       --include_roi $V1Use \
			       --wm_fodnorm $wm_fodnorm \
                               --ResultRoot $TrackGeneration_ResultRoot \
                               --TrackName $TrackName_LGN2V1 \
			       --TrackMaxLength $TrackMaxLength_LGN2V1

	python=/home/oxygen/anaconda3/bin/python
	VoxelConnection_ResultRoot=result/VoxelConnection/
	LGN2V1Track=$TrackGeneration_ResultRoot/track_${TrackName_LGN2V}-S5000.C2.MaxL${TrackMaxLength_LGN2V}.tck
	TrackedROIName=${h}.V1_exvivo-${TrackName_LGN2V}-S5000.C2.MaxL${TrackMaxLength_LGN2V}
	$python src/VoxelConnection.py  $V1Use \
					$VoxelConnection_ResultRoot \ 
					$LGN2V1Track \
					$TrackedROIName
done



