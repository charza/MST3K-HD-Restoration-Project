# == The Avisynth Script that was used for the POC displayed on Youtube ==
# == Here: https://youtu.be/yiCSIQVV8VI so if you want to see how I     ==
# == made it all work, here it is.                                      ==

# NOTE: Frame Numbers for Trim() Are in NTSC-Video FPS (A.K.A. "30000/1001")
hddelay = 565 # Frame That Syncs W/ Theater

# From Opening in Theater to Title Card End
hdstart1 = hddelay-hddelay
hdend1 = 3463

hdstart2 = 5476
hdend2 = 0

upScale = false # 720p BlowUp or Not (Saves Time When Editing if False)

compare = true # 1280x480 Comparison Of Video (DO NOT USE WHEN UPSCALE IS True!!!)

mkvV = MPEG2Source("S02E12_mst.d2v", cpu=0).ConvertToYV12(interlaced = true) #MST3K Episode MPEG2 Index made with DGIndex (Hardware Acceleration is much faster)
mkvA = NicAC3Source("S02E12_eng.ac3", channels=2, drc=1) # MST3K Episode Dolby Digital 2ch Audio

hdV = DirectShowSource("1973 Gojira tai Megaro.720p.ac3.CG.avi", audio=false, video=true, convertfps=false) # HD Movie to Re-Insert (mine was an XviD-encoded AVI, so it was a slow-render.)
hdA = NicAC3Source("1973 Godzilla Vs. Megalon.720p.2ch.jpn.ac3", channels=2, drc=1) # HD Movie Original Audio (For Syncing purposes, I only use the Episode audio when rendering.)

mkvIN   = AudioDub(mkvV, mkvA).YadifMod(order=-1, edeint=mkvV.nnedi3(field=-1)).ChangeFPS("ntsc_video") # Deinterlaces EP and sets to NTSC_Video FPS
hdIN = AudioDub(hdV, hdA).Lanczos4Resize(1696, 720).Crop(388, 0, 960, 720).Lanczos4Resize(640, 480).ChangeFPS("ntsc_video") # Scales Movie and Crops to 4:3 AR

mkv   = mkvIN.Trim(12696, 0).Crop(12,0,-12,-12).Lanczos4Resize(640, 480)#.BlowUpmod(nnu=true,exsharp=true,thSAD=256,thSAD2=96,limit=102,tr=2,LSF=true,var=1.0,uvar=0.0,smode=2,W=960,H=720)# BlowUpMod did not help at all, hense it is commented out
hd = hdIN.Trim(hddelay, 0).ConvertToRGB32() # Gets the Movie rip ready.

luma = mkv.Greyscale().Levels(0, 0.125, 25, 0, 255, coring=true) # this line isolates the Lumakeyed Shadowrama, it needs to be written better so that it's tweakable and better read
mask = luma.Invert("Y").ConvertToRGB32(interlaced=false) # inverts the Image to be used as a mask
lumakey = luma.ConvertToRGB32(interlaced=false).Mask(mask) # masks the Shadowrama so it can be added to movie

inVhd = AlignedSplice(hd.Trim(hdstart1,hdend1),hd.Trim(hdstart2,hdend2))#.ConvertToRGB32(interlaced=false) # Ignore the RGB Conversion on this line, only needed for the masking 
inVsd = lumakey.ConvertToRGB32(interlaced=false)
#inVsd = AlignedSplice(luma.Trim(?, ?), Trim(?,?)) 
inAhd = inVhd.KillVideo() # movie audio trimed
inAsd = inVsd.KillVideo() # episode audio trimed


mergeV = Layer(inVhd, inVsd, op="add", level=257, x=0, y=0, threshold=0, use_chroma=false) # adds shadorama to movie
mergeA = inAsd.MixAudio(inAhd, clip1_factor=0.5, clip2_factor=0.5) # mixes both audio sources for syncing tests

# Everything seen in POC before theatre segment
preRollV = hdIN.Trim(0,hddelay).Subtitle("'GvM' HDTV 720p", x=620, y=460, first_frame=5, last_frame=hddelay-15, font="Arial", size=24, text_color=$00FFFFFF, halo_color=$000000, align=3, spc=0, font_width=0.0, font_angle=0.0, interlaced=False).AddBorders(640, 0, 0, 0, color=$000000)#.Overlay(mkvIN.Trim(12696-hddelay,12696).Crop(12,0,-12,-12).Lanczos4Resize(640, 480).Subtitle("MST3K Vol. 10.0 Disc 1", x=20, y=20, first_frame=5, last_frame=12696-15, font="Arial", size=24, text_color=$00FFFFFF, halo_color=$000000, align=7, spc=0, font_width=0.0, font_angle=0.0, interlaced=False), x=20, y=20, opacity=1.0, mode="add")
preRollA = mkvIN.Trim(12696-hddelay,12696).KillVideo()
preroll = AudioDub(preRollV, preRollA)

# Theatre comparison
compareV = mergeV.Subtitle("Finished Output", x=620, y=460, first_frame=5, last_frame=mergeV.framecount-15, font="Arial", size=24, text_color=$00FFFFFF, halo_color=$000000, align=3, spc=0, font_width=0.0, font_angle=0.0, interlaced=False).AddBorders(640, 0, 0, 0, color=$000000)
original = mkvIN.Trim(12696-hddelay, 0).Crop(12,0,-12,-12).Lanczos4Resize(640, 480).Subtitle("MST3K Vol. 10.0 Disc 1", x=20, y=20, first_frame=5, last_frame=mkvIn.framecount-15-hddelay, font="Arial", size=24, text_color=$00FFFFFF, halo_color=$000000, align=7, spc=0, font_width=0.0, font_angle=0.0, interlaced=False)
#, x=0, y=0, opacity=1.0, mode="add") # ignore!

outA = inAsd # only episode audio used for output
outV = compareV # setting output video
out = UnalignedSplice(preroll, outV.ConvertToYV12(interlaced=false)) # puts preroll video before the finished comparison
finV = out.Overlay(original, x=0, y=0, opacity=1.0, mode="add") # puts the unaltered segment next to the processed to show difference
return AudioDub(finV, original.KillVideo()).AddBorders(0, 120, 0, 120).Subtitle("MST3K HD Remaster Project", x=640, y=60, first_frame=0, last_frame=mergeV.framecount-1, font="Arial", size=48, text_color=$00FFFFFF, halo_color=$000000, align=5, spc=0, font_width=0.0, font_angle=0.0, interlaced=False).Subtitle("Proof-Of-Concept #1: Experiment 0212", x=640, y=660, first_frame=0, last_frame=mergeV.framecount-1, font="Arial", size=48, text_color=$00FFFFFF, halo_color=$000000, align=5, spc=0, font_width=0.0, font_angle=0.0, interlaced=False)#.ConvertToYV12(interlaced=false)#return # text to show throughout

