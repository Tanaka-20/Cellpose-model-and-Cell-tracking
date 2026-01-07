// ===== Per-image paired mask measurement (w1 image ↔ w0 mask), TopHat=50 =====
// Each fluorescence image has a paired mask:
//   image: A01_x0_y0_w1.tif
//   mask : A01_x0_y0_w0_mask.tif
// This version includes safety checks to prevent "no image open" errors.

inputDir  = "C:\\Users\\mudzimtb\\Downloads\\spectra max\\25_08_13_Edu_ToPro_RWL_concentrations_1\\25_08_13_Edu_ToPro_RWL_concentrations\\Expt1\\Plate1\\IMAGES\\test\\eduall\\";
outputCSV = inputDir + "Combined_FluoMask_TopHat50.csv";

// ---- user params ----
DECIMALS      = 3;
TOPHAT_R      = 50;       // rolling-ball radius (pixels)
USE_WATERSHED = false;    // split touching objects in mask?
ERODE_STEPS   = 0;        // 0=none; 1..2 to tighten ROIs
// ----------------------

setBatchMode(true);

// Fresh Results table and activate Label column
run("Clear Results");
setOption("ExpandableArrays", true);
setResult("Label", 0, "prime_label_init");
updateResults();
run("Clear Results");

// Measurement settings (includes 'label')
run("Set Measurements...", "area mean min max integrated label decimal=" + DECIMALS);

// Directory listing
list = getFileList(inputDir);

// --- helper: find paired mask for w1 image ---
function pairedMaskFor(imgName) {
    if (!endsWith(imgName, ".tif")) return "";
    base = replace(imgName, ".tif", "");
    idx = lastIndexOf(base, "_w1");
    if (idx < 0) return "";
    left = substring(base, 0, idx);
    right = substring(base, idx + lengthOf("_w1"), lengthOf(base));
    maskBase = left + "_w0" + right;
    maskName = maskBase + "_mask.tif";
    full = inputDir + maskName;
    if (File.exists(full)) return full;
    return "";
}

// ========== MAIN LOOP ==========
for (i = 0; i < list.length; i++) {
    name = list[i];
    if (!endsWith(name, ".tif")) continue;

    lname = toLowerCase(name);
    if (indexOf(lname, "_mask") >= 0 || indexOf(lname, "mask") >= 0) continue;
    if (indexOf(lname, "_w1") < 0) continue;  // only fluorescence images

    maskPath = pairedMaskFor(name);
    if (maskPath == "") {
        print("⚠️ Skipping (no paired mask found for): " + name);
        continue;
    }

    // --- 1) Open mask and verify it opened ---
    open(maskPath);
    if (nImages() < 1) {
        print("⚠️ Could not open mask: " + maskPath);
        continue;
    }

    maskTitle = getTitle();
    selectWindow(maskTitle);
    run("32-bit");
    setThreshold(1, 1e9);
    setOption("BlackBackground", true);
    run("Convert to Mask");

    if (USE_WATERSHED) run("Watershed");
    for (e = 0; e < ERODE_STEPS; e++) run("Erode");

    // Build ROIs from mask (no results pollution)
    roiManager("Reset");
    run("Analyze Particles...", "size=0-Infinity show=Nothing add");
    nROI = roiManager("count");
    if (nROI < 1) {
        close(maskTitle);
        print("⚠️ No ROIs found in mask: " + maskPath);
        continue;
    }

    maskW = getWidth(); maskH = getHeight();
    close(maskTitle);

    // --- 2) Open the fluorescence image and verify ---
    rawPath = inputDir + name;
    open(rawPath);
    if (nImages() < 1) {
        print("⚠️ Could not open image: " + rawPath);
        roiManager("Reset");
        continue;
    }

    rawTitle = getTitle();
    measW = getWidth(); measH = getHeight();
    if (measW != maskW || measH != maskH) {
        close(rawTitle);
        roiManager("Reset");
        print("⚠️ Skipping (mask/image size mismatch): " + name);
        continue;
    }

    // --- 3) Background subtraction (TopHat = 50 px) ---
    if (nSlices > 1) run("Subtract Background...", "rolling="+TOPHAT_R+" stack");
    else             run("Subtract Background...", "rolling="+TOPHAT_R);

    // --- 4) Measure all ROIs ---
    roiManager("Select All");
    startRow = nResults;
    roiManager("Measure");
    endRow = nResults;

    // Tag rows with filename
    for (r = startRow; r < endRow; r++) {
        setResult("Label", r, name);
    }
    updateResults();

    close(rawTitle);
    roiManager("Reset");
}

// --- 5) Save combined results ---
saveAs("Results", outputCSV);
setBatchMode(false);
print("✅ Done. Saved: " + outputCSV + "  (filenames in 'Label' column')");
