# Sai so ap sac/xa so voi du lieu, can theo Ah tinh tu trang thai day da nghi (khong can OCV): python3 hyst_khoang_cach.py <thu_muc_artifact> [bien_the]
import csv,glob,sys,math
D=sys.argv[1]; var=sys.argv[2] if len(sys.argv)>2 else 'base'
def fl(x):
    try: return float(x)
    except: return float('nan')
rows=[];ph=[]
for p in glob.glob(D+'/**/hyst_%s_*_decomp.csv'%var,recursive=True): rows+=list(csv.DictReader(open(p)))
for p in glob.glob(D+'/**/hyst_%s_*_phases.csv'%var,recursive=True): ph+=list(csv.DictReader(open(p)))
def curve(pts):
    pts=sorted([p for p in pts if not math.isnan(p[0]) and not math.isnan(p[1])])
    def f(x):
        for i in range(len(pts)-1):
            if pts[i][0]<=x<=pts[i+1][0]:
                w=(x-pts[i][0])/(pts[i+1][0]-pts[i][0]) if pts[i+1][0]>pts[i][0] else 0
                return pts[i][1]+w*(pts[i+1][1]-pts[i][1])
        return float('nan')
    return f
print('T cell crate | d(Ah from full) : Vch_exp Vdis_exp G_exp | Vch_sim Vdis_sim G_sim | Gsim-Gexp (mV) | ch err, dis err')
for T in ['0','10','25']:
    for cell in sorted(set(r['cell'] for r in rows if r['T_degC']==T)):
        pc=[r for r in ph if r['T_degC']==T and r['cell']==cell and r['type']=='CHA' and r['after_dis']=='1']
        pd=[r for r in ph if r['T_degC']==T and r['cell']==cell and r['type']=='DCH' and r['block']=='12']
        if not pc or not pd: continue
        qa=fl(pc[0]['q_after']); q0d=fl(pd[0]['q0'])
        ch=[r for r in rows if r['T_degC']==T and r['cell']==cell and r['kind']=='1' and r['block']==pc[0]['block']]
        di=[r for r in rows if r['T_degC']==T and r['cell']==cell and r['kind']=='4' and r['block']=='12']
        fce=curve([(fl(r['d_exp']),fl(r['V_exp'])) for r in ch]); fde=curve([(fl(r['d_exp']),fl(r['V_exp'])) for r in di])
        fcs=curve([(fl(r['q_bal'])-qa,fl(r['V'])) for r in ch]); fds=curve([(fl(r['q_bal'])-q0d,fl(r['V'])) for r in di])
        out=[]
        for d in [0.54,0.6,0.8,1.0,1.5,2.0,3.0]:
            a,b,c,e=fce(d),fde(d),fcs(d),fds(d)
            out.append('d=%.2f: %.0f/%.0f/%.0f | %.0f/%.0f/%.0f | %+.0f | %+.0f,%+.0f'%(d,1e3*a,1e3*b,1e3*(a-b),1e3*c,1e3*e,1e3*(c-e),1e3*((c-e)-(a-b)),1e3*(c-a),1e3*(e-b)))
        print(T,cell,pd[0]['crate_file'],'q_after',round(qa,3),'q0dis',round(q0d,3),'\n   '+'\n   '.join(out))
