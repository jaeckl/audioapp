from PIL import Image, ImageDraw
W, H = 832, 1216
im = Image.new("RGB", (W, H), "black")
d = ImageDraw.Draw(im)
p = {"nose": (416,165), "neck": (416,300), "rs": (320,340), "re": (292,520), "rw": (315,720), "ls": (512,340), "le": (540,520), "lw": (517,720), "rh": (370,850), "lh": (462,850), "reye": (392,150), "leye": (440,150), "rear": (365,165), "lear": (467,165)}
edges = [("neck","rs",(255,85,0)),("rs","re",(255,170,0)),("re","rw",(255,255,0)),("neck","ls",(170,255,0)),("ls","le",(85,255,0)),("le","lw",(0,255,0)),("neck","rh",(0,255,85)),("neck","lh",(0,170,255)),("neck","nose",(85,0,255)),("nose","reye",(170,0,255)),("reye","rear",(255,0,255)),("nose","leye",(255,0,170)),("leye","lear",(255,0,85))]
for a,b,color in edges: d.line((p[a],p[b]),fill=color,width=16)
for x,y in p.values(): d.ellipse((x-10,y-10,x+10,y+10),fill="white")
im.save(r"C:\Users\ludwi\Desktop\audioapp\output\hatch-pet\velora-comfy-v2\references\upperbody-idle-openpose.png")
