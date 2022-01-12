#script implementing https://stackoverflow.com/questions/18141055/ffmpeg-commands-to-concatenate-different-type-and-resolution-videos-into-1-video
repeats = 5
import glob
mp4s = glob.glob("*.mp4")
import os


with open("inputvideos.txt","w") as f:
    for index,filename in enumerate(mp4s):
        if "__merge__" not in filename and "__temp__" not in filename:
            tempfile = "__temp__%i.mp4"%index
            os.system("ffmpeg -i \""+filename+"\" -acodec libvo_aacenc -vcodec libx264 -s 1920x1080 -r 60 -strict experimental "+tempfile)
            for i in range(repeats):
                f.write("file '")
                f.write(tempfile)
                f.write("'\n")

os.system("ffmpeg -f concat -safe 0 -i inputvideos.txt -c copy __merge__.mp4")

temps = glob.glob("__temp__*.mp4")
for filename in temps:
    os.remove(filename)