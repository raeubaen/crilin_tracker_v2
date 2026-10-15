#!/usr/bin/env python3
import sys
from pathlib import Path
from array import array
import glob

import numpy as np
import pandas as pd
import uproot
import ROOT

##############################################################################
# CONFIG
##############################################################################

CSV_FILE = "scan_positions.csv"

X_COL = "x"
Y_COL = "y"
RUN_COL = "run"

TREE_NAME = "tree"

ROOT_BASE = Path("/eos/home-r/rgargiul/tracker_runs")

BEAM_MIN = 9.0
BEAM_MAX = 18.0

LOG_WEIGHT_OFFSET = float(sys.argv[1])

##############################################################################
# TRACKER GEOMETRY
##############################################################################

##############################################################################
# UTILITIES
##############################################################################

def find_root_files(run_number):

    run_dir = ROOT_BASE / f"run_{run_number}"

    pattern = str(
        run_dir /
        f"reco_run_{run_number:07d}_*.root"
    )

    return sorted(glob.glob(pattern))


def logarithmic_centroid(charges, x, y):

    charges = np.asarray(
        charges,
        dtype=np.float64
    )

    tot = np.sum(charges)

    if tot <= 0:
        return None

    fractions = charges / tot

    weights = np.maximum(
        0.0,
        LOG_WEIGHT_OFFSET + np.log(fractions + 1e-8)
    )

    sw = np.sum(weights)

    if sw <= 0:
        return None

    xrec = np.sum(
        weights * x
    ) / sw

    yrec = np.sum(
        weights * y
    ) / sw

    return xrec, yrec

##############################################################################
# LOAD CSV
##############################################################################

scan = pd.read_csv(CSV_FILE)

run_to_xy = {}

for _, row in scan.iterrows():

    run_to_xy[int(row[RUN_COL])] = (
        float(row[X_COL]),
        float(row[Y_COL])
    )

##############################################################################
# OUTPUT ARRAYS
##############################################################################

arr_run = []

arr_true_x = []
arr_true_y = []

arr_rx_d = []
arr_ry_d = []

arr_rx_u = []
arr_ry_u = []

##############################################################################
# LOOP RUNS
##############################################################################

for run in sorted(run_to_xy):

    true_x, true_y = run_to_xy[run]

    files = find_root_files(run)

    if len(files) == 0:
        print("missing run", run)
        continue

    print("processing run", run)

    for fname in files:

        try:

            tree = uproot.open(fname)[TREE_NAME]

            qd = tree["tracker_d_charge"].array(
                library="np"
            )

            qu = tree["tracker_u_charge"].array(
                library="np"
            )

            xd = tree["tracker_d_x"].array(
                library="np"
            )

            yd = tree["tracker_d_y"].array(
                library="np"
            )

            xu = tree["tracker_u_x"].array(
                library="np"
            )

            yu = tree["tracker_u_y"].array(
                library="np"
            )


            bc = tree[
                "beamcatcher_charge_sum"
            ].array(library="np")

        except Exception as e:

            print("skip", fname, e)
            continue

        mask = (
            np.isfinite(bc)
            &
            (bc > BEAM_MIN)
            &
            (bc < BEAM_MAX)
        )

        qd = qd[mask]
        qu = qu[mask]

        xd = xd[mask]
        xu = xu[mask]

        yd = yd[mask]
        yu = yu[mask]

        for i in range(len(qd)):

            reco_d = logarithmic_centroid(
                qd[i], xd[i], yd[i]
            )

            reco_u = logarithmic_centroid(
                qu[i], xu[i], yu[i]
            )

            if reco_d is None:
                continue

            if reco_u is None:
                continue

            arr_run.append(run)

            arr_true_x.append(true_x)
            arr_true_y.append(true_y)

            arr_rx_d.append(reco_d[0])
            arr_ry_d.append(reco_d[1])

            arr_rx_u.append(reco_u[0])
            arr_ry_u.append(reco_u[1])

##############################################################################
# NUMPY
##############################################################################

arr_run = np.asarray(arr_run)

arr_true_x = np.asarray(arr_true_x)
arr_true_y = np.asarray(arr_true_y)

arr_rx_d = np.asarray(arr_rx_d)
arr_ry_d = np.asarray(arr_ry_d)

arr_rx_u = np.asarray(arr_rx_u)
arr_ry_u = np.asarray(arr_ry_u)

##############################################################################
# ROOT FILE
##############################################################################

fout = ROOT.TFile(
    f"tracker_logcentroid_w{int(LOG_WEIGHT_OFFSET*100)}_percent.root",
    "RECREATE"
)

##############################################################################
# TREE
##############################################################################

tree = ROOT.TTree(
    "recoTree",
    "recoTree"
)

run_b = array('i',[0])

tx_b = array('d',[0.0])
ty_b = array('d',[0.0])

rxd_b = array('d',[0.0])
ryd_b = array('d',[0.0])

rxu_b = array('d',[0.0])
ryu_b = array('d',[0.0])

tree.Branch("run",run_b,"run/I")

tree.Branch("true_x",tx_b,"true_x/D")
tree.Branch("true_y",ty_b,"true_y/D")

tree.Branch("reco_x_d",rxd_b,"reco_x_d/D")
tree.Branch("reco_y_d",ryd_b,"reco_y_d/D")

tree.Branch("reco_x_u",rxu_b,"reco_x_u/D")
tree.Branch("reco_y_u",ryu_b,"reco_y_u/D")

for i in range(len(arr_run)):

    run_b[0] = int(arr_run[i])

    tx_b[0] = arr_true_x[i]
    ty_b[0] = arr_true_y[i]

    rxd_b[0] = arr_rx_d[i]
    ryd_b[0] = arr_ry_d[i]

    rxu_b[0] = arr_rx_u[i]
    ryu_b[0] = arr_ry_u[i]

    tree.Fill()

##############################################################################
# HISTOS
##############################################################################

n = len(arr_true_x)

ones = np.ones(
    n,
    dtype=np.float64
)

hRecoVsTrueX_D = ROOT.TH2F(
    "hRecoVsTrueX_D",
    ";True X [mm];Reco X [mm]",
    120,-15,15,
    120,-15,15
)

hRecoVsTrueX_D.FillN(
    n,
    arr_true_x,
    arr_rx_d,
    ones
)

hRecoVsTrueY_D = ROOT.TH2F(
    "hRecoVsTrueY_D",
    ";True Y [mm];Reco Y [mm]",
    120,-15,15,
    120,-15,15
)

hRecoVsTrueY_D.FillN(
    n,
    arr_true_y,
    arr_ry_d,
    ones
)

hRecoVsTrueX_U = ROOT.TH2F(
    "hRecoVsTrueX_U",
    ";True X [mm];Reco X [mm]",
    120,-15,15,
    120,-15,15
)

hRecoVsTrueX_U.FillN(
    n,
    arr_true_x,
    arr_rx_u,
    ones
)

hRecoVsTrueY_U = ROOT.TH2F(
    "hRecoVsTrueY_U",
    ";True Y [mm];Reco Y [mm]",
    120,-15,15,
    120,-15,15
)

hRecoVsTrueY_U.FillN(
    n,
    arr_true_y,
    arr_ry_u,
    ones
)

hUpDownX = ROOT.TH2F(
    "hUpDownX",
    ";Reco X upstream;Reco X downstream",
    120,-15,15,
    120,-15,15
)

hUpDownX.FillN(
    n,
    arr_rx_u,
    arr_rx_d,
    ones
)

hUpDownY = ROOT.TH2F(
    "hUpDownY",
    ";Reco Y upstream;Reco Y downstream",
    120,-15,15,
    120,-15,15
)

hUpDownY.FillN(
    n,
    arr_ry_u,
    arr_ry_d,
    ones
)

##############################################################################
# RUN BY RUN
##############################################################################

for run in np.unique(arr_run):

    mask = (arr_run == run)

    nn = np.count_nonzero(mask)

    w = np.ones(nn)

    hd = ROOT.TH2F(
        f"hRecoXY_D_run{run}",
        f"run {run};Reco X;Reco Y",
        120,-15,15,
        120,-15,15
    )

    hd.FillN(
        nn,
        arr_rx_d[mask],
        arr_ry_d[mask],
        w
    )

    hu = ROOT.TH2F(
        f"hRecoXY_U_run{run}",
        f"run {run};Reco X;Reco Y",
        120,-15,15,
        120,-15,15
    )

    hu.FillN(
        nn,
        arr_rx_u[mask],
        arr_ry_u[mask],
        w
    )

    hd.Write()
    hu.Write()

##############################################################################
# WRITE
##############################################################################

tree.Write()

hRecoVsTrueX_D.Write()
hRecoVsTrueY_D.Write()

hRecoVsTrueX_U.Write()
hRecoVsTrueY_U.Write()

hUpDownX.Write()
hUpDownY.Write()

fout.Close()

print("tracker_logcentroid.root written")
