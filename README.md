# Cellpose model and cell tracking


## Introduction 

Phase Contrast is a light microscopy technique used to enhance the contrast of images of transparent and colourless specimens.
And a fluorescent image is an image captured using a fluorescence microscope, where fluorescent dyes or proteins are excited by light of a specific wavelength and then emit light at a longer wavelength. The emitted light is detected and visualized as bright regions against a dark background.

Objective:


To quantify EdU (fluorescent) signal intensities across six treatment conditions by generating accurate cell masks from phase-contrast images using a fine-tuned Cellpose model.

Rationale:


Fluorescence microscopy provides spatial and intensity-based information on biological activity. However, manual segmentation is time-consuming and prone to variability. The goal was to use deep learning-based segmentation to automate this process with high precision.

Experimental Setup


Image Samples

- Conditions: Six different  treatments A-C (Condition 1–6).
- Image Types per condition:
	- Phase contrast images – used for cell model custom tuning for segmentation (creating ROIs).
	- EdU fluorescence images – proliferation marker with Edu(green colour).acts as a phluorescent channel.
	- TO-PRO-3 fluorescence images – label  for total cell count reference.

Model Training Workflow


Base Model

The Cellpose algorithm was originally trained on more than 70,000 segmented cells from diverse datasets, enabling strong generalization across cell types and imaging modalities.

Fine-Tuning Rationale

While Cellpose performs well out-of-the-box, fine-tuning improves accuracy for images that differ from the general training set (e.g., unique morphologies, contrast variations, or noise).

Iterative Training Cycle


Following the attached flow cycle above. 
1. Annotation:
   Manual correction of segmentation results on selected images (as shown in the attached flow diagram).
2. Model Training:
   The corrected regions were used to retrain the model.
3. Correction and Validation:
   The model was tested on new images, and errors were corrected in subsequent iterations.

Training Dataset Details

Used a total training set of 5 images, with almost 4,500–4,700  regions of intrests (ROIs)and  each image manually refined to ensure accurate cell boundary detection.
Image
Approx. ROI Count (Before Fine-Tuning)
After Fine-Tuning
Image 1
about 670
749
Image 2
close to 820
951
Image 3
1084
1 118
Image 4
about 1000
1 121
Image 5
1 091
1 120

Model Improvement

The fine-tuned model demonstrated increased segmentation accuracy (e.g., improved ROI count from 1084 to 1 118 in Image 3). As shown below in pictures. same picture on the base model vs on the custom tuned model 
Performance verified visually and by comparing cell count consistency across test images.




Automated Segmentation and ROI Generation (Python Workflow)

Segmentation in Python
- The fine-tuned Cellpose model was implemented in a Python environment to perform automated segmentation on all phase-contrast images from the six conditions.
- For each image, the model generated:
	- Segmentation masks (as labeled _mask tif).
	- ROI coordinates corresponding to detected cells.
- The python code used is in the notebook attached below.





Output generation

Each segmented image was automatically saved as a mask file, where each cell region was uniquely labeled.

These mask images served as input for downstream fluorescence quantification.

ROI Transfer to Fiji

The generated mask files were imported into Fiji (ImageJ) using a custom macro script.
The macro extracted individual ROIs (regions of interest) from each mask and applied them precisely to the corresponding EdU fluorescence images to ensure pixel-to-pixel alignment with the phase-contrast segmentation.


Fluorescence Quantification (Fiji Workflow)

Background Subtraction
- To eliminate uneven illumination and background fluorescence, a rolling-ball radius of 50 pixels was applied to each EdU image prior to intensity measurement.
To fix an uneven background use the menu command Process › Subtract background. This will use a rolling ball algorithm on the uneven background. The radius should be set to at least the size of the largest object that is not part of the background. It can also be used to remove background from gels where the background is white. Running the command several times may produce better results. The user can choose whether or not to have a light background, create a background with no subtraction, have a sliding paraboloid, disable smoothing, or preview the results. The default value for the rolling ball radius is 50 pixels. https://imagej.net/imaging/image-intensity-processing

   Intensity Measurement
- Using the imported ROIs, Fiji measured mean fluorescence intensity, integrated density, and area for every segmented cell.
- Measurements were exported automatically to Excel/CSV files per condition.
Data Consolidation
- The exported spreadsheets were aggregated and organized by treatment condition (Condition 1 – 6), forming the basis for statistical and visual analyses.

Data Analysis and Visualization

1. Combined fluorescence data were analyzed in  R and box plots/violin plots were generated:
showing per-cell EdU intensity distributions across six conditions.




Discussion

The combination of Cellpose deep-learning segmentation with Fiji-based fluorescence quantification provided an efficient and reproducible workflow for single-cell analysis.
Fine-tuning on only five images (with close to1000 ROIs each) significantly improved model precision, increasing the number of correctly identified cells and enhancing mask accuracy.
By coupling the automated segmentation from Python with quantitative fluorescence measurements in Fiji, the pipeline minimized manual error, standardized data collection, and allowed for direct comparison of EdU intensity across all six treatment conditions.

Conclusion 

Fine-tuning of Cellpose significantly improved segmentation accuracy and cell count consistency.
The hybrid Python + Fiji pipeline streamlined the process—combining:
- Deep-learning segmentation (Python),
- ROI-based fluorescence measurement (Fiji),
- Quantitative visualization (R/Python).
- Shifts in mean intensity reflect condition-dependent modulation of DNA synthesis activity.
- Broader distributions indicate heterogeneity within the cell populations.
The approach achieved single-cell precision with minimal manual correction and strong reproducibility.
