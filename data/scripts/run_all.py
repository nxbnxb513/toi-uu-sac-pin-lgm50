"""Re-download the open datasets and regenerate every file in data/derived/.

Usage:  python data/scripts/run_all.py [--cache DIR]
Needs:  Python >= 3.9, numpy, pandas, scipy, openpyxl   (pip install -r data/scripts/requirements.txt)
Network: zenodo.org only (about 70 MB in total; the 49 GB / 835 MB archives are read by HTTP Range).
"""
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
STEPS = ["a_tec_noise_thermal.py", "b_oregan_tidy_entropy.py", "c_li2025_ageing.py", "d_kirkaldy_summary.py"]

if __name__ == "__main__":
    for s in STEPS:
        print("=== " + s, flush=True)
        subprocess.check_call([sys.executable, os.path.join(HERE, s)] + sys.argv[1:])
