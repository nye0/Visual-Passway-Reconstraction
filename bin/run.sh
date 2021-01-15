#!/bin/bash
DIR=/home/yy/Documents/XY/TCB/Visual-Passway-Reconstraction-master/
python=/home/yy/anaconda3/bin/python
NumberOfThreads=10


RawDWI_AP=$DIR/data/100610/unprocessed/3T/Diffusion/100610_3T_DWI_dir95_LR.nii.gz
#data/YQ_DTI_AP/
PE=LR
RPE=all
RPE_Image=$DIR/data/100610/unprocessed/3T/Diffusion/100610_3T_DWI_dir95_RL.nii.gz
DTIpre_ResultRoot=$DIR/result/DTIpre/

T1Image=$DIR/data/100610//unprocessed/3T/T1w_MPR1/100610_3T_T1w_MPR1.nii.gz
#data/YQ_T1_0006/
T2Image=$DIR/data/100610//unprocessed/3T/T2w_SPC1/100610_3T_T2w_SPC1.nii.gz
#data/YQ_T2_0007/
SubjectID=100610
ROIExtraction_ResultRoot=$DIR/result/ROIExtraction/
SUBJECTS_DIR=$ROIExtraction_ResultRoot/freesurfer/
ROIUseRoot=$ROIExtraction_ResultRoot/ROIUse/

FS_T1Orig=$SUBJECTS_DIR/$SubjectID/mri/orig/001.mgz
PreprocessedDTI=$DTIpre_ResultRoot/DWI-raw-den-unr-mdc-unbiased.mif
BrainMask=$DTIpre_ResultRoot/DWI-raw-den-unr-mdc-unbiased-unb-fslbet.mif
FiberEstimation_ResultRoot=$DIR/result/FiberEstimation/

a="
src/DTIpre.sh  --RawImage=$RawDWI_AP \
	       --RawImage_PE=$PE \
	       --RPE=$RPE \
	       --RPE_Image=$RPE_Image \
	       --ResultRoot=$DTIpre_ResultRoot 



#export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=$NumberOfThreads
src/ROIExtraction-Opti.LGN.V1.sh --SubjectID=$SubjectID \
			    --T1Image=$T1Image \
			    --T2Image=$T2Image \
			    --ResultRoot=$ROIExtraction_ResultRoot



src/FiberEstimation.sh --PreprocessedImage=$PreprocessedDTI \
		       --T1Image=$FS_T1Orig \
		       --BrainMask=$BrainMask \
		       --ResultRoot=$FiberEstimation_ResultRoot 
"
# Track Generation
TrackGeneration_ResultRoot=result/TrackGeneration/
DWI2T1=$FiberEstimation_ResultRoot/diff2struct-mrtrix.txt
TrackMaxLength_Op2LGN=50
TrackMaxLength_LGN2V1=100
tt5=$FiberEstimation_ResultRoot/5tt-coreg.mif
wm_fodnorm=$FiberEstimation_ResultRoot/fod_wm-norm.mif

# T1 ROI transform
TransformedROIRoot=$TrackGeneration_ResultRoot/ROI.T1Orig2DWI/

for h in lh rh; do
	LGN=$ROIUseRoot/T1Orig-${h}.LGN.nii.gz
	V1=$ROIUseRoot/T1Orig-${h}.V1_exvivo.nii.gz
	OpticalNerve=$ROIUseRoot/T1Orig-${h}.OptialNerve.nii.gz
	for roi in $LGN $V1 $OpticalNerve; do
		src/ROI2DWI.sh $roi $DWI2T1 $TransformedROIRoot
	done
done

# Tracking between ROI
TrackRoot=$TrackGeneration_ResultRoot/TracksBetweenROIs/
VoxelConnection_ResultRoot=$TrackGeneration_ResultRoot/VoxelConnections/
for h1 in lh rh; do
	LGNUse=$TransformedROIRoot/T1Orig-${h1}.LGN-DWI.mif
        V1Use=$TransformedROIRoot/T1Orig-${h1}.V1_exvivo-DWI.mif
	TrackGeneration_Result=$TrackGeneration_ResultRoot/track/
	TrackName_LGN2V1=${h1}.LGN2V1
	src/TrackGeneration.sh --act=$tt5 \
                               --seed_roi=$LGNUse \
                               --include_roi=$V1Use \
                               --wmfod_norm=$wm_fodnorm \
                               --ResultRoot=$TrackRoot \
                               --TrackName=$TrackName_LGN2V1 \
                               --TrackMaxLength=$TrackMaxLength_LGN2V1

        #/home/oxygen/anaconda3/bin/python
        LGN2V1Track=$TrackRoot/track_${TrackName_LGN2V1}-S5000.C2.MaxL${TrackMaxLength_LGN2V1}.tck
        TrackedROIName=${h}.V1_exvivo-${TrackName_LGN2V1}-S5000.C2.MaxL${TrackMaxLength_LGN2V1}
        $python src/VoxelConnection.py  $V1Use \
                                        $VoxelConnection_ResultRoot \
                                        $LGN2V1Track \
                                        $TrackedROIName
	for h2 in lh rh; do
		OpticalNerveUse=$TransformedROIRoot/T1Orig-${h2}.OptialNerve-DWI.mif
		TrackName_Op2LGN=${h2}.OpticalNerve2${h1}.LGN
		src/TrackGeneration.sh	--act=$tt5 \
                              		--seed_roi=$OpticalNerveUse \
                              		--include_roi=$LGNUse \
                              		--wmfod_norm=$wm_fodnorm \
                              		--ResultRoot=$TrackRoot \
                              		--TrackName=$TrackName_Op2LGN \
                              		--TrackMaxLength=$TrackMaxLength_Op2LGN
	done
done





