import re,sys,glob,os
M="~/dev/stdio-noob/mes-0.25.1/lib/linux/x86_64-mes/"
L="~/dev/stdio-noob/mes25-build/libcbuild/"
files=[M+"elf64-header.hex2",L+"crt1.o","tcc_fixed.o",L+"abort.o"]
files+=sorted(f for f in glob.glob(L+"*.o") if os.path.basename(f) not in("crt1.o","abort.o"))
files+=[M+"elf64-footer-single-main.hex2"]
base=0x08048000; pos=0; labels=[]
for f in files:
    for line in open(f,errors="replace"):
        line=re.split(r'[#;]',line)[0] if not line.lstrip().startswith(("'",'"')) else line
        for t in line.split():
            c=t[0]
            if c==':': labels.append((base+pos,t[1:],os.path.basename(f))); continue
            if c=='<' : continue
            if c in '&%': pos+=4; continue
            if c=='!': pos+=1; continue
            if c in '$@': pos+=2; continue
            if c=='~': pos+=3; continue
            if c=="'": pos+=1; continue
            if c=='"': pos+=len(t)-2; continue
            if re.fullmatch(r'[0-9a-fA-F]+',t): pos+=len(t)//2
            # else: ignore
labels.sort()
d=dict((n,a) for a,n,_ in labels)
print("computed _start=%#x (ELF says 0x8048300)"%d.get("_start",0))
for target in map(lambda x:int(x,16),sys.argv[1:]):
    prev=[l for l in labels if l[0]<=target][-1]
    print("%#x -> %s+%#x  (from %s)"%(target,prev[1],target-prev[0],prev[2]))
