# Visual-Passway-Reconstraction
使用Mrtrix3基于DTI，重建视辐射
# can be use to analyse HCP data

# Two Step Registration  Example
```
antsRegistrationSyN.sh -d 3 -f ct1.nii -m meanafunc.nii -t 'r' -o f2a_
antsRegistrationSyN.sh -d 3 -f MNI152_T1_1mm.nii.gz -m ct1.nii -o a2t_
antsApplyTransforms -d 3 -i rafunc.nii -o wra.nii.gz -r EPI_3mm.nii -t a2t_1Warp.nii.gz -t a2t_0GenericAffine.mat -t f2a_0GenericAffine.mat -e 3 
```
