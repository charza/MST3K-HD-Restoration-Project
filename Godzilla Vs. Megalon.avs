#Write your script here, then Save it (Ctrl+S) and Exit (Alt+X).
#Note: this script will be opened using Import(), so you can`t change it later!

mkvV = MPEG2Source("S02E12_mst.d2v", cpu=0).ConvertToYV12(interlaced = true)
mkvA = NicAC3Source("S02E12_eng.ac3", channels=2, drc=1)

hdV = DirectShowSource("1973 Gojira tai Megaro.720p.ac3.CG.avi", audio=false, video=true, convertfps=false)
hdA = NicAC3Source("1973 Godzilla Vs. Megalon.720p.2ch.jpn.ac3", channels=2, drc=1)

mkvIN   = AudioDub(mkvV, mkvA).YadifMod(order=-1, edeint=mkvV.nnedi3(field=-1)).ChangeFPS("ntsc_video")
hdIN = AudioDub(hdV, hdA).Lanczos4Resize(1696, 720).Crop(388, 0, 960, 720)#.Lanczos4Resize(640, 480)

mkv   = mkvIN.Trim(12696, 0).Crop(12,0,-12,-12).BlowUpmod(nnu=true,exsharp=true,thSAD=256,thSAD2=96,limit=102,tr=2,LSF=true,var=1.0,uvar=0.0,smode=2,W=960,H=720)#.Lanczos4Resize(960, 720)
hd = hdIN.Trim(466, 0).ChangeFPS("ntsc_video").ConvertToRGB32()

luma = mkv.Greyscale().Levels(0, 0.125, 25, 0, 255, coring=true)
mask = luma.Invert("Y").ConvertToRGB32(interlaced=false)
lumakey = luma.ConvertToRGB32(interlaced=false).Mask(mask)

inAhd = hd.KillVideo()
inAsd = mkv.KillVideo()

mergeV = Layer(hd, lumakey, op="add", level=257, x=0, y=0, threshold=0, use_chroma=false)
mergeA = inAsd#.MixAudio(inAhd, clip1_factor=0.5, clip2_factor=0.5)

out = AudioDub(mergeV, mergeA)
return out.ConvertToYV12(interlaced=false)