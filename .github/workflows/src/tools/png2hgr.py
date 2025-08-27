# path: tools/png2hgr.py
#!/usr/bin/env python3
from PIL import Image
import sys
W,H=280,192
BASE=0x2000

def row_addr(y):
    return BASE + (y & 0x07)*0x80 + (y & 0x38)*5 + (y & 0xC0)*0x28

def main(inp,out):
    img=Image.open(inp).convert('L').resize((W,H))
    data=bytearray(0x2000)
    for y in range(H):
        ya=row_addr(y)-BASE
        for col in range(40):
            b=0; x0=col*7
            for bit in range(7):
                x=x0+bit
                if x>=W: break
                if img.getpixel((x,y))<128:
                    b|=(1<<bit)
            data[ya+col]=b & 0x7F
    with open(out,'wb') as f:
        f.write(data)

if __name__=='__main__':
    if len(sys.argv)!=3:
        print('Usage: png2hgr.py in.png out.hgr',file=sys.stderr);sys.exit(1)
    main(sys.argv[1],sys.argv[2])
