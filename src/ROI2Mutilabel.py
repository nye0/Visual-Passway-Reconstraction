import sys,os
import SimpleITK as sitk
from subprocess import call

RawROIPath=sys.argv[1]
OutputPath=sys.argv[2]
ResultRoot=os.path.dirname(OutputPath)

if RawROIPath.split('.')[-1]=='mif':
    ROIPath='.'.join(RawROIPath.split('.')[:-1]+['nii.gz'])
    call(["mrconvert",RawROIPath,ROIPath])
else:
    ROIPath=RawROIPath

if not os.path.exists(ResultRoot):
    os.makedirs(ResultRoot)

Mask0=sitk.ReadImage(ROIPath,sitk.sitkFloat64)
Mask0_array=sitk.GetArrayFromImage(Mask0)
Mask0_array[Mask0_array>0]=list(range(1,len(Mask0_array[Mask0_array>0])+1))
Mask1=sitk.GetImageFromArray(Mask0_array)
if Mask1.GetSize()==Mask0.GetSize():
    Mask1.CopyInformation(Mask0)
else:
    print("Image Size Changed, Please check!")
    exit
sitk.WriteImage(Mask1,OutputPath)
