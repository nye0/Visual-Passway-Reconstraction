#!/bin/bash

src/DTIpre.sh  --RawImage=data/YQ_DTI_AP/ \
	       --RawImage_PE=AP \
	       --RPE=all \
	       --RPE_Image=data/YQ_DTI_PA/ \
	       --ResultRoot=./result/DTIpre/ &
src/ROIExtraction-V1.LGN.sh --SubjectID=YQ_0006 \
			    --T1Image=data/YQ_T1_0006/ \
			    --T2Image=data/YQ_T2_0007/ \
			    --ResultRoot=/media/oxygen/y2/202002/git/Visual-Passway-Reconstraction/result/ROIExtraction/

src/FiberEstimation.sh --PreprocessedImage=result/DTIpre/DWI-raw-den-unr-mdc-unbiased.mif \
		       --T1Image=../freesurfer_LGNextraction/result/YQ_0006/mri/orig/001.nii.gz \
		       --BrainMask=result/DTIpre/DWI-raw-den-unr-mdc-unbiased-unbrain_mask.mif \
		       --ResultRoot=result/FiberEstimation/

src/ROI2DWI.sh result/ROIExtraction/ROIUse/T1Orig-lh.V1_exvivo.nii.gz result/FiberEstimation/diff2struct-mrtrix.tx

