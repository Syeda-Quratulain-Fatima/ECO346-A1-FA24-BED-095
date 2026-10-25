import os
import numpy as np
import pandas as pd
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

# ---- 1. read and merge ----
person = pd.read_csv("data/pslm_person_subset.csv")
hh = pd.read_csv("data/pslm_hh_subset.csv")

d = person.merge(hh[["hhid", "hhweight", "prov_code", "urban_rural"]],
                 on="hhid", how="left")

# ---- 2. variant 7: Balochistan urban earners aged 15-64 ----
d = d[(d.prov_code == 4) & (d.urban_rural == 2) &
      (d.age >= 15) & (d.age <= 64) & (d.earn_annual > 0)].copy()
print("earners:", len(d))

# ---- 3. age bands (left-closed: [15,20), [20,25), ...) ----
labels = [f"{a}-{a+4}" for a in range(15, 65, 5)]
d["band"] = pd.cut(d["age"], bins=list(range(15, 70, 5)),
                   right=False, labels=labels)
d["mid"] = 15 + 5 * ((d["age"] - 15) // 5) + 2

# ---- 4. band table: n and weighted mean ----
d["wx"] = d["hhweight"] * d["earn_annual"]
bands = (d.groupby(["band", "mid"], observed=True)
           .agg(n=("age", "size"), sw=("hhweight", "sum"), swx=("wx", "sum"))
           .reset_index())
bands["wmean"] = bands["swx"] / bands["sw"]
bands["wmean_rs"] = bands["wmean"].round().astype(int)
bands["thin"] = bands["n"] < 30
print(bands[["band", "mid", "n", "wmean", "wmean_rs", "thin"]].to_string())

os.makedirs("output", exist_ok=True)
bands_out = bands[["band", "n", "wmean_rs"]].copy()
bands_out["band"] = bands_out["band"].astype(str)
bands_out.to_csv("output/band_table_python.csv", index=False)

# ---- 5. compare with the R table ----
r = pd.read_csv("output/band_table_R.csv")
r["band"] = r["band"].astype(str)
same = r.reset_index(drop=True).equals(bands_out.reset_index(drop=True))
print("R and Python band tables identical to the rupee:", same)

# ---- 6. figure ----
rng = np.random.default_rng(346)
x = d["age"] + rng.uniform(-0.4, 0.4, size=len(d))

fig, ax = plt.subplots(figsize=(8, 5.5))
ax.scatter(x, d["earn_annual"], s=8, color="dimgray", alpha=0.4, linewidths=0)
ax.plot(bands["mid"], bands["wmean"], color="firebrick", linewidth=1.8)

solid = bands[~bands["thin"]]
hollow = bands[bands["thin"]]
ax.scatter(solid["mid"], solid["wmean"], s=45, color="firebrick", zorder=3)
ax.scatter(hollow["mid"], hollow["wmean"], s=45, facecolors="none",
           edgecolors="firebrick", linewidths=1.5, zorder=3)

peak = bands.loc[bands["wmean"].idxmax()]
ax.annotate(f"Highest band: ages {peak['band']}\nRs {peak['wmean_rs']:,}",
            xy=(peak["mid"], peak["wmean"]),
            xytext=(peak["mid"] - 2, peak["wmean"] * 2.2),
            ha="center", color="firebrick", fontweight="bold")

ax.set_yscale("log")
ax.set_ylim(1e4, 1e7)
ax.set_yticks([1e4, 1e5, 1e6, 1e7])
ax.set_yticklabels(["10,000", "100,000", "1,000,000", "10,000,000"])
ax.minorticks_off()
ax.set_xlim(14, 65)
ax.set_xticks(range(15, 70, 5))
ax.set_xlabel("Age (years)")
ax.set_ylabel("Annual earnings (Rs, log scale)")
ax.set_title("Urban Balochistan earnings rise until the late 20s, plateau into the 40s, then edge up;\n"
             f"the highest band mean ({peak['band']}) rests on only {peak['n']} earners",
             fontsize=10, fontweight="bold")
ax.grid(color="lightgray", linewidth=0.5)
for s in ("top", "right"):
    ax.spines[s].set_visible(False)

fig.text(0.01, 0.01,
         f"Source: PSLM 2019-20 person file. Sample: earners aged 15-64, Balochistan urban (n = {len(d)}). "
         "Weighted by hhweight.\nRed markers: weighted mean earnings by 5-year age band, plotted at band midpoint; "
         "hollow markers: fewer than 30 earners in the band.",
         fontsize=6.5, ha="left", va="bottom")
fig.tight_layout(rect=(0, 0.06, 1, 1))

os.makedirs("figures", exist_ok=True)
fig.savefig("figures/relationship_python.svg")
print("saved figures/relationship_python.svg")
