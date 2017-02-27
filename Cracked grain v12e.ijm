/*
 * Macro v12e for detection of Hanasaki cracks in soaked rice grain
 * Last modified: 9 Nov, 2016
 * Mark Talbot, DPI NSW, Yanco Ag
 *
========================================================================================================
 Macro assumes input images have dimensions of 5184 x 3456 pixels. If not, it upscales or downscales
 the image to these dimensions. It is recommended to ensure that if the size is different, take an
 image of higher value dimensions, since upscaling from smaller dimensions will result in loss of detail
========================================================================================================
 
 Classification of cracks:

	H1 = one or more Hanasaki cracks with associated fissures that extend at least half-way into grain,  
		fissures can be located elsewhere in the grain
	H2 = one or more Hanasaki cracks, with no detectable associated fissures. Fissures can be located
		elsewhere in the grain
	F1 = one or more fissures that extend into grain that appear to cleave the grain. Might be
		Hanasaki, but difficult to tell
	F2 = one or more fine fissures, which may be healed cracks. These are not considered
		Hanasaki and are therefore not counted as cracked in this macro
*/

input = getDirectory("Choose Source Directory ");
output = getDirectory("Choose Destination Directory ");


Dialog.create("Cracked grain classification options");
Dialog.addCheckbox("Run macro with default values?", true);
//Dialog.addMessage("If unchecked, default vaules for cracked\ngrain classification can be changed");
Dialog.addCheckbox("Create detailed colour overlays?", true);
//Dialog.addMessage("If checked, grains and cracks will\n be overlaid with colours according to\ncrack type");
//Dialog.addMessage("If unchecked, grains will be\nlabelled as cracked or not cracked");
Dialog.addCheckbox("Create overlays on original plate image?", false);
//Dialog.addMessage("If checked, overlays will be\n created on grain 'catalogs'\nas well as the original image");
//Dialog.addMessage("If unchecked, overlays will be\n created on grain 'catalogs' only");
Dialog.show();

default = Dialog.getCheckbox();
deatil_overlay = Dialog.getCheckbox();
plate_overlay = Dialog.getCheckbox();

if (default==false){
	Dialog.create("Cracked grain classification options");
	Dialog.addNumber("Min crack to grain width ratio:", 0.33);
	Dialog.addNumber("Min Hanasaki (H2) grey SD:", 25);
	Dialog.addNumber("Min Hanasaki (H2) area:", 34);
	Dialog.addNumber("Min Fissure grey SD:", 16);
	Dialog.addNumber("Min Fissure area:", 34);
	Dialog.show();

	minCwr = Dialog.getNumber();
	minH2_StDev = Dialog.getNumber();
	minH2_Area = Dialog.getNumber();
	minF_StDev = Dialog.getNumber();
	minF_Area = Dialog.getNumber();
}
if (default==true){
	minCwr = 0.33;
	minH2_StDev = 25;
	minH2_Area = 34;
	minF_StDev = 16;
	minF_Area = 34;
}
T1 = "Macro variable values used";
T2 = "["+T1+"]";
T3 = T2;
run("Text Window...", "name="+T2);
print(T3, "Variables used in test: \n");
print(T3, "\n");
print(T3, "Min crack to grain width ratio = "+minCwr+"\n");
print(T3, "Min Hanasaki (H2) grey SD = "+minH2_StDev+"\n");
print(T3, "Min Hanasaki (H2) area = "+minH2_Area+"\n");
print(T3, "Min Fissure grey SD = "+minF_StDev+"\n");
print(T3, "Min Fissure area = "+minF_Area+"\n");
selectWindow(T1);
outputfile = "Macro variable values used";
fullpath = output + outputfile;
saveAs(".txt", fullpath);

if (isOpen("Macro variable values used.txt")) {
	selectWindow("Macro variable values used.txt");
	run("Close");
}

list = getFileList(input);
for (i = 0; i < list.length; i++){
	cracking(input, output, list[i]);
	selectWindow("Cracking results");
	saveAs("Measurements", output + "cracking_results.csv");
}

function cracking(input, output, filename) {
	//setBatchMode(true);
	showProgress(i+1, list.length);
	open(input + filename);
	original=getTitle();
	dotIndex = indexOf(original, ".");
	title = substring(original, 0, dotIndex);
	run("Set Measurements...", "  redirect=None decimal=2");
	run("Colors...", "foreground=white background=black selection=green");
	if (is("grayscale")==false){
 	run("8-bit");
 	}

/*check if image is right size*/
	width = getWidth();
	height = getHeight();
	if(width != 5184 && height != 3456){
		run("Scale...", "x=- y=- width=5184 height=3456 interpolation=Bilinear average create title=original");
	}
	else{
		run("Duplicate...", "title=original");
	}

/*crop original image*/
	selectWindow("original");
	run("Duplicate...", "title=crop");
	selectWindow("crop");
	run("Auto Threshold", "method=Triangle");
	run("Invert");
	run("Analyze Particles...", "size=20000-Infinity circularity=0.8-1.00 show=Masks exclude in_situ");
	run("Create Selection");
	run("Make Inverse");
	run("To Bounding Box");
	run("Scale... ", "x=1.08 y=1.08 centered");
	selectWindow("original");
	run("Restore Selection");
	run("Crop");
	close("crop");
	selectWindow("original");
	run("Select None");

/*create grains image*/
	/*smooth image to remove air bubbles and some debris and improve threshold*/
	selectWindow("original");
	run("Morphological Filters", "operation=Closing element=Disk radius=6");
	rename("full-grains-smooth");
	run("Statistical Region Merging", "q=2 showaverages");
	rename("full-grains-SRM");
	run("8-bit");

	selectWindow("full-grains-SRM");
	run("Threshold...");
	setThreshold(0, 183);
	run("Convert to Mask");
	run("Close");

	selectWindow("full-grains-smooth");
	run("Bilateral Filter", "spatial=6 range=50");
	close("full-grains-smooth");
	selectWindow("full-grains-smooth-6.0-50.0");
	rename("full-grains-smooth");
	run("Threshold...");
	setThreshold(0, 176);
	setOption("BlackBackground", true);
	run("Convert to Mask");
	run("Close");
	run("Analyze Particles...", "size=5000-Infinity show=Masks in_situ");
	if (isOpen("Log")) {
         selectWindow("Log");
         run("Close");
     } 

	selectWindow("original");
	run("Duplicate...", "title=plate");
	selectWindow("plate");
	run("Auto Threshold", "method=Triangle");
	run("Analyze Particles...", "size=10000-Infinity show=Masks in_situ");
	run("Create Selection");
	run("Scale... ", "x=0.82 y=0.82 centered");
	selectWindow("full-grains-smooth");
	run("Restore Selection");
	run("Make Inverse");
	run("Colors...", "foreground=black background=white selection=green");
	run("Fill", "slice");
	run("Colors...", "foreground=white background=white selection=green");
	run("Select None");
	run("Adjustable Watershed", "tolerance=7");
	run("Fill Holes");

	selectWindow("plate");
	selectWindow("full-grains-SRM");
	run("Restore Selection");
	run("Make Inverse");
	run("Colors...", "foreground=black background=white selection=green");
	run("Fill", "slice");
	run("Colors...", "foreground=white background=white selection=green");
	run("Select None");
	run("Adjustable Watershed", "tolerance=7");
	run("Fill Holes");

	imageCalculator("AND create", "full-grains-SRM","full-grains-smooth");
	close("full-grains-SRM");
	close("full-grains-smooth");
	selectWindow("Result of full-grains-SRM");
	rename("full-grains");
	setOption("BlackBackground", true);
	run("Make Binary");
	run("Adjustable Watershed", "tolerance=7");

	/*create a 'filled grain' to remove Hanasaki cracks*/
	selectWindow("plate");
	selectWindow("full-grains");
	run("Restore Selection");
	run("Analyze Particles...", "size=5000-Infinity show=Masks exclude add in_situ");
	run("Select None");
	for (i=0 ; i<roiManager("count"); i++) {
		roiManager("select", i);
		run("Enlarge...", "enlarge=20");
		run("Enlarge...", "enlarge=-20");
		run("Fill", "slice");
		roiManager("Update");
		}

	if (isOpen("ROI Manager")) {
				selectWindow("ROI Manager");
				run("Close");
		}
	run("Remove Overlay");
	//setBatchMode("exit and display");

	/*filter grains image*/
	if (isOpen("Results")) {
	selectWindow("Results");
	run("Close");
	}
	selectWindow("full-grains");
	run("Select None");
	run("Adjustable Watershed", "tolerance=7");
	run("Clear Results");
	run("Particles8 ", "white morphology show=Particles minimum=0 maximum=9999999 display overwrite redirect=None");
	//run("Classify Particles", "class[1]=PerEquivD operator[1]=> value[1]=110 class[2]=PerEquivD operator[2]=< value[2]=160 class[3]=-empty- operator[3]=-empty- value[3]=0.0000 class[4]=-empty- operator[4]=-empty- value[4]=0.0000 combine=[AND (match all)] output=[Keep members] white");
		//this PerEquivD range is not working, tried different range, below:
	run("Classify Particles", "class[1]=PerEquivD operator[1]=> value[1]=90 class[2]=PerEquivD operator[2]=< value[2]=130 class[3]=-empty- operator[3]=-empty- value[3]=0.0000 class[4]=-empty- operator[4]=-empty- value[4]=0.0000 combine=[AND (match all)] output=[Keep members] white");

	close("full-grains");
	selectWindow("Subset");
	rename("full-grains");
	if (isOpen("Results")) {
	selectWindow("Results");
	run("Close");
	}
	close("plate");

/*create 'reduced' grain area for selection*/
	//setBatchMode(true);
	run("Analyze Particles...", "size=5000-Infinity show=Masks exclude add in_situ");
	for (i=0 ; i<roiManager("count"); i++) {
		roiManager("select", i);
		run("Enlarge...", "enlarge=-20");
		run("Enlarge...", "enlarge=18");
		run("Fill", "slice");
		roiManager("Update");
		}
	run("Select None");
	run("Duplicate...", "title=full-grains-reduced");
	run("Select All");
	run("Colors...", "foreground=black background=white selection=green");
	run("Fill", "slice");
	run("Select None");
	run("Colors...", "foreground=white background=black selection=green");
	run("From ROI Manager");
	for (i=0 ; i<roiManager("count"); i++) {
		roiManager("select", i);
		run("Fill", "slice");
		roiManager("Update");
		}
	if (isOpen("ROI Manager")) {
		selectWindow("ROI Manager");
		run("Close");
		}
	run("Remove Overlay");
	run("Select None");

/*create Hanasaki image*/
	/*filter original image to remove debris (also used for cracks image)*/
	selectWindow("original");
	run("Duplicate...", "title=filtered");
	run("Duplicate...", "title=DoG");
	run("Difference of Gaussians", "  sigma1=4 sigma2=1");
	run("Enhance Contrast...", "saturated=4 normalize");
	run("Threshold...");
	setThreshold(32, 255);
	run("Convert to Mask");
	run("Close");
	run("Analyze Particles...", "  circularity=0.85-1.00 show=Masks in_situ");
	run("Create Selection");
	selectWindow("filtered");
	run("Restore Selection");
	run("Make Inverse");
	run("Enlarge...", "enlarge=2");
	run("Median...", "radius=6");
	run("Select None");
	close("DoG");
	selectWindow("filtered");
	run("Morphological Filters", "operation=Closing element=Disk radius=4");
	run("Unsharp Mask...", "radius=4 mask=0.60");
	run("Threshold...");
	setAutoThreshold("Default");
	setThreshold(0, 173);
	run("Convert to Mask");
	run("Close");

	selectWindow("full-grains");
	if (isOpen("ROI Manager")) {
		selectWindow("ROI Manager");
		run("Close");
	}
	run("Remove Overlay");
	run("Select None");
	run("Create Selection");
	selectWindow("filtered-Closing");
	run("Restore Selection");
	run("Enlarge...", "enlarge=2");
	run("Colors...", "foreground=white background=black selection=green");
	run("Fill", "slice");
	run("Select None");
	run("Invert");

	run("Duplicate...", "title=selector");
	selectWindow("full-grains-reduced");
	run("Create Selection");
	selectWindow("selector");
	run("Restore Selection");
	run("Enlarge...", "enlarge=5");
	//setBatchMode("exit and display");

	run("Colors...", "foreground=black background=black selection=green");
	run("Fill", "slice");
	run("Select None");
	run("Binary Feature Extractor", "objects=filtered-Closing selector=selector object_overlap=0");
	selectWindow("Extracted_filtered-Closing-1");
	rename("Hanasaki");
	
	close("selector");
	close("filtered-Closing");
	selectWindow("Hanasaki");
	setOption("BlackBackground", true);
	run("Make Binary");
	
	run("Particles8 ", "white morphology show=Particles filter minimum=10 maximum=9999999 display redirect=original");
	run("Classify Particles", "class[1]=Area operator[1]=> value[1]=10 class[2]=EquivEllAr operator[2]=> value[2]=18 class[3]=GrStDev operator[3]=> value[3]=8 class[4]=Roundness operator[4]=> value[4]=0.1 combine=[AND (match all)] output=[Keep members] white");
	close("Hanasaki");
	selectWindow("Subset");
	rename("Hanasaki");
	if (isOpen("Results")) {
		selectWindow("Results");
		run("Close");
		}

/*create cracks image*/
	/*ridge-detection*/
	//setBatchMode(true);
	selectWindow("filtered");
	run("Ridge Detection", "line_width=4 high_contrast=50 low_contrast=10 extend_line method_for_overlap_resolution=NONE sigma=1.08 lower_threshold=0.68 upper_threshold=3.40");
	run("To ROI Manager");
	roiManager("Show All without labels");
	run("Duplicate...", "title=cracks");
	run("Select All");
	run("Colors...", "foreground=black background=black selection=green");
	setForegroundColor(0, 0, 0);
	run("Fill", "slice");
	run("Select None");
	run("From ROI Manager");
	run("Flatten");
	close("filtered");
	close("cracks");
	selectWindow("cracks-1");
	rename("cracks");
	run("8-bit");
	run("Threshold...");
	setThreshold(3, 255);
	setOption("BlackBackground", true);
	run("Convert to Mask");
	run("Close");
	selectWindow("original");
	run("Remove Overlay");
	if (isOpen("ROI Manager")) {
				selectWindow("ROI Manager");
				run("Close");
			}
	selectWindow("full-grains");
	run("Create Selection");
	selectWindow("cracks");
	run("Restore Selection");
	run("Enlarge...", "enlarge=2");
	run("Colors...", "foreground=black background=black selection=green");
	run("Fill", "slice");
	run("Select None");
	run("Options...", "iterations=1 count=1 black do=Nothing");
	setOption("BlackBackground", true);
	run("Dilate");
	run("Close-");

	run("Duplicate...", "title=selector");
	selectWindow("full-grains-reduced");
	run("Create Selection");
	selectWindow("selector");
	run("Restore Selection");
	run("Enlarge...", "enlarge=12");
	
	run("Colors...", "foreground=black background=black selection=green");
	run("Fill", "slice");
	run("Select None");
	selectWindow("cracks");
	run("Select None");
	run("Binary Feature Extractor", "objects=cracks selector=selector object_overlap=0");
	close("cracks");
	selectWindow("Extracted_cracks-1");
	rename("cracks");
	close("selector");
	
	run("Particles8 ", "white morphology show=Particles filter minimum=30 maximum=9999999 display redirect=original");

	for (i = 0; i < nResults; i++){
		A = getResult("Area", i);
		P = getResult("Perim", i);
		R = getResult("MaxR", i);
		FormFactor = 16*A*A/(PI*P*(R*2)*(R*2)*(R*2)); //form factor based on Grum and Sturm 1995, Acta Stereol 14(1): 91-96, replaces circularity and roundness
		setResult("FormFactor", i, FormFactor);
		updateResults();
		}
	//setBatchMode("exit and display");
	run("Classify Particles", "class[1]=FormFactor operator[1]=< value[1]=0.07 class[2]=Feret operator[2]=> value[2]=20 class[3]=GrStDev operator[3]=> value[3]=8 class[4]=Compactness operator[4]=< value[4]=0.5 combine=[AND (match all)] output=[Keep members] white");
	close("cracks");
	selectWindow("Subset");
	rename("cracks");
	if (isOpen("Results")) {
		selectWindow("Results");
		run("Close");
	}
	
	
/*Create set of images separating crack types*/
	/*Hanasaki that extend into grain with cracks (H1)*/
	run("Binary Feature Extractor", "objects=cracks selector=Hanasaki object_overlap=0 combine");
	rename("Cracks with Hanasaki");
	/*'Total cracks' image (Cracks added to Hanasaki)*/
	imageCalculator("Add create", "cracks","Hanasaki");
	selectWindow("Result of cracks");
	rename("Cracks+Hanasaki");
	/*Cracks that are not associated with Hanasaki (F1 and F2)*/
	imageCalculator("Subtract create", "Cracks+Hanasaki","Cracks with Hanasaki");
	selectWindow("Result of Cracks+Hanasaki");
	rename("Fissures");
	/*Hanasaki with cracks (H1, but without the cracks)*/
	run("Binary Feature Extractor", "objects=Hanasaki selector=[Cracks with Hanasaki] object_overlap=0");
	rename("Hanasaki with cracks");
	/*Hanasaki that are not associated with cracks (H2)*/
	imageCalculator("Subtract create", "Hanasaki","Hanasaki with cracks");
	selectWindow("Result of Hanasaki");
	rename("Hanasaki without cracks");
	close("Hanasaki with cracks");

/*Analyze grains and cracks to determine the extent of crack formation*/
	//setBatchMode(true);
	close("grains");
	selectWindow("full-grains");
	run("Select None");
	rename("grains");
	selectWindow("grains");
	run("Duplicate...", "title=grains-temp");
	close("grains");
	selectWindow("grains-temp");
	rename("grains");
	run("Analyze Particles...", " show=Nothing add");
	run("Duplicate...", "title=cracked-1");
	selectWindow("cracked-1");
	run("Select All");
	run("Colors...", "foreground=black background=black selection=green");
	setForegroundColor(0, 0, 0);
	run("Fill", "slice");
	run("Select None");
	run("Duplicate...", "title=cracked-2");
	run("Duplicate...", "title=cracked-3");
	run("Duplicate...", "title=not-cracked");
	selectWindow("cracked-1");
	run("From ROI Manager");
	selectWindow("cracked-2");
	run("From ROI Manager");
	selectWindow("cracked-3");
	run("From ROI Manager");
	selectWindow("not-cracked");
	run("From ROI Manager");
	selectWindow("Cracks with Hanasaki");
	run("From ROI Manager");
	selectWindow("Fissures");
	run("From ROI Manager");
	selectWindow("Hanasaki without cracks");
	run("From ROI Manager");

	a1 = "Cracking";
	a2 = "["+a1+"]";
	a=a2;

	run("Set Measurements...", "area mean standard modal min fit feret's median redirect=original decimal=2");
	run("Clear Results");

	for (i=0 ; i<roiManager("count"); i++) {
		selectWindow("Cracks with Hanasaki");
		roiManager("select", i);
		G=(i+1); //grain (ROI) number
		run("Measure");
		Gwidth = getResult("Minor", 0); //grain width - to compare with crack length
		run("Clear Results");
		run("Analyze Particles...", "display");
		H1=nResults; //number of Hanasaki with cracks (H1) per grain
		if (H1 > 0){
			run("Summarize");
			H1_length = getResult("Feret"); //max crack 'legth'
			H1_Stdev = getResult("StdDev"); //max standard deviation of crack grey values
		}
		else if (H1 == 0){
			H1_length = 0;
			H1_Stdev = 0;
		}
		selectWindow("Hanasaki without cracks");
		roiManager("select", i);
		run("Analyze Particles...", "display");
		H2=nResults; //number of Hanasaki with cracks (H1) per grain
		if (H2 > 0){
			run("Summarize");
			H2_Stdev = getResult("StdDev"); //max standard deviation of crack grey values
			H2_Area = getResult("Area"); //max standard deviation of crack grey values
		}
		else if (H2 == 0){
			H2_Stdev = 0;
			H2_Area = 0;
		}
		selectWindow("Fissures");
		roiManager("select", i);
		run("Analyze Particles...", "display");
		F=nResults; //number of Hanasaki with cracks (H1) per grain
		if (F > 0){
			run("Summarize");
			F_length = getResult("Feret"); //max crack 'legth'
			F_Area = getResult("Area"); //max standard deviation of crack grey values
			F_Stdev = getResult("StdDev");
		}
		else if (F == 0){
			F_length = 0;
			F_Area = 0;
			F_Stdev = 0;
		}
		H1wr = (H1_length/Gwidth); //H1 crack length to grain width ratio
		Fwr = (F_length/Gwidth); //Fissure length to grain width ratio
		minCwr = 0.33; //minimum crack-width ratio value (approx 1/3 to 1/2 the grain width)
		H3 = H1 + H2; //add Hanasaki crack results together
	
		run("Clear Results");
	
		if (H1 > 0){
			/*CRACKED-1: Hanasaki crack/s plus one or more large fissures*/
			cracked="H1";
			selectWindow("cracked-1");
			roiManager("select", i);
			run("Colors...", "foreground=white background=black selection=green");
			run("Fill", "slice");
		}
		else if (H1 == 0){
			if (H2 > 0){
				if (H2_Area >= minH2_Area){
					/*CRACKED-2*/
					cracked="H2";
					selectWindow("cracked-2");
					roiManager("select", i);
					run("Colors...", "foreground=white background=black selection=green");
					run("Fill", "slice");
				}
				else if (H2_Area <= minH2_Area){
					if (F > 0){
						if (Fwr >= minCwr){
							if (F_Stdev >= minF_StDev){
								/*CRACKED-3: no Hanasaki cracks but large fissures*/
								cracked="F1";
								selectWindow("cracked-3");
								roiManager("select", i);
								run("Colors...", "foreground=white background=black selection=green");
								run("Fill", "slice");
							}
							else if (F_Stdev <= minF_StDev){
								/*NOT-CRAKCED: fissures present, but possibly healed 'stress' cracks*/
								cracked="F2";
								selectWindow("not-cracked");
								roiManager("select", i);
								run("Colors...", "foreground=white background=black selection=green");
								run("Fill", "slice");
							}
						}
						else if (Fwr <= minCwr){
							if (F_Area >= minF_Area){
								if (F_Stdev >= minF_StDev){
									/*CRACKED-2*/
									cracked="H2";
									selectWindow("cracked-2");
									roiManager("select", i);
									run("Colors...", "foreground=white background=black selection=green");
									run("Fill", "slice");
								}
								else if (F_Stdev <= minF_StDev){
									/*NOT-CRAKCED: fissures present, but possibly healed 'stress' cracks*/
									cracked="F2";
									selectWindow("not-cracked");
									roiManager("select", i);
									run("Colors...", "foreground=white background=black selection=green");
									run("Fill", "slice");
								}
							}
							else if (F_Area <= minF_Area){
								/*NOT-CRAKCED*/
								cracked="F2";
								selectWindow("not-cracked");
								roiManager("select", i);
								run("Colors...", "foreground=white background=black selection=green");
								run("Fill", "slice");
							}
						}
					}
					else if (F == 0){
						/*NOT-CRAKCED*/
						cracked="NC";
						selectWindow("not-cracked");
						roiManager("select", i);
						run("Colors...", "foreground=white background=black selection=green");
						run("Fill", "slice");
					}
				}
			}
			else if (H2 == 0){
				if (F > 0){
					if (Fwr >= minCwr){
						if (F_Stdev >= minF_StDev){
							/*CRACKED-3: no Hanasaki cracks but large fissures*/
							cracked="F1";
							selectWindow("cracked-3");
							roiManager("select", i);
							run("Colors...", "foreground=white background=black selection=green");
							run("Fill", "slice");
						}
						else if (F_Stdev <= minF_StDev){
							/*NOT-CRAKCED*/
							cracked="F2";
							selectWindow("not-cracked");
							roiManager("select", i);
							run("Colors...", "foreground=white background=black selection=green");
							run("Fill", "slice");
						}
					}
					else if (Fwr <= minCwr){
						if (F_Area >= minF_Area){
							if (F_Stdev >= minF_StDev){
								/*CRACKED-2*/
								cracked="H2";
								selectWindow("cracked-2");
								roiManager("select", i);
								run("Colors...", "foreground=white background=black selection=green");
								run("Fill", "slice");
							}
							else if (F_Stdev <= minF_StDev){
								/*NOT-CRAKCED*/
								cracked="F2";
								selectWindow("not-cracked");
								roiManager("select", i);
								run("Colors...", "foreground=white background=black selection=green");
								run("Fill", "slice");
							}
						else if (F_Area <= minF_Area){
							/*NOT-CRAKCED*/
							cracked="F2";
							selectWindow("not-cracked");
							roiManager("select", i);
							run("Colors...", "foreground=white background=black selection=green");
							run("Fill", "slice");
							}
						}
					}
				}
				else if (F == 0){
					/*NOT-CRAKCED*/
					cracked="NC";
					selectWindow("not-cracked");
					roiManager("select", i);
					run("Colors...", "foreground=white background=black selection=green");
					run("Fill", "slice");
				}
			}
		}
		
							
		if (isOpen(a1)){
		print(a, G + "\t" + Gwidth + "\t" + H3 + "\t" + H1wr + "\t" + H1_Stdev + "\t" + H2_Stdev + "\t" + H2_Area + "\t" + F + "\t" + Fwr + "\t" + F_Stdev + "\t" + F_Area + "\t" + cracked);
		}
		else {
			run("New... ", "name="+a2+" type=Table");
			print(a,"\\Headings:Grain #\tWidth\t# Hanasaki\tHanasaki-Width ratio\tH1 Grey SD\tH2 Grey SD\tH2 Area\t# Fissures\tFissure-Width ratio\tF Grey SD\tF Area\tCracked? \n");
			print(a, G + "\t" + Gwidth + "\t" + H3 + "\t" + H1wr + "\t" + H1_Stdev + "\t" + H2_Stdev + "\t" + H2_Area + "\t" + F + "\t" + Fwr + "\t" + F_Stdev + "\t" + F_Area + "\t" + cracked);
		}
	}
	if (isOpen("Results")) {
		selectWindow("Results");
		run("Close");
	}
	run("Set Measurements...", "area mean standard modal min fit feret's median redirect=None decimal=2");
/*count number of grains in each class*/
		selectWindow("cracked-1");
		run("Select None");
		run("Remove Overlay");
		run("Adjustable Watershed", "tolerance=7");
		run("Analyze Particles...", "display");
		nH1 = nResults();
		run("Clear Results");

		selectWindow("cracked-2");
		run("Select None");
		run("Remove Overlay");
		run("Adjustable Watershed", "tolerance=7");
		run("Analyze Particles...", "display");
		nH2 = nResults();
		run("Clear Results");

		selectWindow("cracked-3");
		run("Select None");
		run("Remove Overlay");
		run("Adjustable Watershed", "tolerance=7");
		run("Analyze Particles...", "display");
		nF1 = nResults();
		run("Clear Results");

		selectWindow("not-cracked");
		run("Select None");
		run("Remove Overlay");
		run("Adjustable Watershed", "tolerance=7");
		run("Analyze Particles...", "display");
		nNC = nResults();
		run("Clear Results");

		CrackedTotal = (nH1 + nH2 + nF1);
		Total = (CrackedTotal + nNC);
		PercentCracked = (CrackedTotal/Total*100);
		run("Clear Results");
		if (isOpen("ROI Manager")) {
			selectWindow("ROI Manager");
			run("Close");
			}

		b1 = "Cracking results";
		b2 = "["+b1+"]";
		b=b2;
		if (isOpen(b1)){
			print(b, title + "\t" + Total + "\t" + CrackedTotal + "\t" + nNC + "\t" + PercentCracked);
			}
		else {run("New... ", "name="+b2+" type=Table");
			print(b, "\\Headings:Title\tTotal\tCracked\tNot cracked\t% Cracked \n");
			print(b, title + "\t" + Total + "\t" + CrackedTotal + "\t" + nNC + "\t" + PercentCracked);
		}


/*create overlay images*/

	if (deatil_overlay==true){
		if (nH1 > 0) {
			selectWindow("cracked-1");
			run("Create Selection");
			run("Make Inverse");
			run("RGB Color");
			setForegroundColor(0, 38, 77); //dark blue
			run("Fill", "slice");
			run("Select None");
		}
		if (nH2 > 0) {
			selectWindow("cracked-2");
			run("Create Selection");
			run("Make Inverse");
			run("RGB Color");
			setForegroundColor(77, 166, 255); //light blue
			run("Fill", "slice");
			run("Select None");
		}
		if (nF1 > 0) {
			selectWindow("cracked-3");
			run("Create Selection");
			run("Make Inverse");
			run("RGB Color");
			setForegroundColor(121, 255, 77); //light green
			run("Fill", "slice");
			run("Select None");
		}
		if (nNC > 0) {
			selectWindow("not-cracked");
			run("Create Selection");
			run("Make Inverse");
			run("RGB Color");
			setForegroundColor(255, 255, 179); //pale yellow
			run("Fill", "slice");
			run("Select None");
		}
		selectWindow("original");
		run("Invert");
		run("Enhance Contrast...", "saturated=1 normalize");
		run("Duplicate...", "title=labels");
		run("RGB Color");
		run("Add Image...", "image=cracked-1 x=0 y=0 opacity=50 zero");
		run("Add Image...", "image=cracked-2 x=0 y=0 opacity=50 zero");
		run("Add Image...", "image=cracked-3 x=0 y=0 opacity=40 zero");
		run("Add Image...", "image=not-cracked x=0 y=0 opacity=35 zero");
	
		selectWindow("Cracks with Hanasaki"); //H1
		run("Select None");
		run("Remove Overlay");
		run("Analyze Particles...", "display");
		nCwH = nResults();
		run("Clear Results");
		if (nCwH>0){
			run("Create Selection");
			run("Make Inverse");
			run("RGB Color");
			setForegroundColor(255, 0, 0); //red
			run("Fill", "slice");
			run("Select None");
		}
	
		selectWindow("Hanasaki without cracks"); //H2
		run("Select None");
		run("Remove Overlay");
		run("Analyze Particles...", "display");
		nHwoC = nResults();
		run("Clear Results");
		if (nHwoC>0){
			run("Create Selection");
			run("Make Inverse");
			run("RGB Color");
			setForegroundColor(255, 64, 0); //orange
			run("Fill", "slice");
			run("Select None");
		}
	
		selectWindow("Fissures");
		run("Select None");
		run("Remove Overlay");
		run("Analyze Particles...", "display");
		nfissures = nResults();
		run("Clear Results");
		if (nfissures>0){
			run("Create Selection");
			run("Make Inverse");
			run("RGB Color");
			setForegroundColor(255, 255, 0); //yellow
			run("Fill", "slice");
			run("Select None");
		}
	
		selectWindow("labels");
		run("Add Image...", "image=[Cracks with Hanasaki] x=0 y=0 opacity=80 zero");
		run("Add Image...", "image=[Hanasaki without cracks] x=0 y=0 opacity=80 zero");
		run("Add Image...", "image=Fissures x=0 y=0 opacity=65 zero");
		run("Flatten");
		close("labels");
		selectWindow("labels-1");
		rename("labels");
	}
	if (deatil_overlay==false){
		imageCalculator("Add", "cracked-1","cracked-2");
		imageCalculator("Add", "cracked-1","cracked-3");
		close("cracked-2");
		close("cracked-3");
		selectWindow("cracked-1");
		rename("cracked");
		run("Create Selection");
		run("Make Inverse");
		run("RGB Color");
		setForegroundColor(26, 140, 255); //blue
		run("Fill", "slice");
		run("Select None");
	
		selectWindow("not-cracked");
		run("Create Selection");
		run("Make Inverse");
		run("RGB Color");
		setForegroundColor(255, 255, 179); //pale yellow
		run("Fill", "slice");
		run("Select None");
	
		selectWindow("original");
		run("Invert");
		run("Enhance Contrast...", "saturated=1 normalize");
		run("Duplicate...", "title=labels");
		run("RGB Color");
		run("Add Image...", "image=cracked x=0 y=0 opacity=50 zero");
		run("Add Image...", "image=not-cracked x=0 y=0 opacity=35 zero");
	
		selectWindow("Cracks+Hanasaki");
		run("Create Selection");
		run("Make Inverse");
		run("RGB Color");
		setForegroundColor(255, 140, 26); //orange
		run("Fill", "slice");
		run("Select None");
		selectWindow("labels");
		run("Add Image...", "image=Cracks+Hanasaki x=0 y=0 opacity=80 zero");
		run("Flatten");
		close("labels");
		selectWindow("labels-1");
		rename("labels");
	}
	//setBatchMode("exit and display");
	selectWindow("grains");
	run("Remove Overlay");
	run("Select None");
	run("Adjustable Watershed", "tolerance=7");
	run("Colors...", "foreground=white background=black selection=green");
	run("Particles8 ", "white morphology show=Particles minimum=0 maximum=9999999 display redirect=None");
	run("Catalogue Particles", "sort=Number order=Ascending redirect=original extract=Wand include_values montage background=Black align");
	selectWindow("Catalog by Number");
	rename("original-catalog");
	selectWindow("grains");
	run("Catalogue Particles", "sort=Number order=Ascending redirect=labels extract=Wand include_values montage background=Black align");
	selectWindow("Catalog by Number");
	rename("labels-catalog");

/*save results csv and images*/
	selectWindow("Cracking");
	saveAs("Measurements", output + title + "_results.xls");
	if (isOpen("Cracking")) {
		selectWindow("Cracking");
		run("Close");
	}
	selectWindow("labels-catalog");
	outputfile = title + "_catalog-label";
	fullpath = output + outputfile;
	saveAs("Jpeg", fullpath);

	selectWindow("original-catalog");
	outputfile = title + "_cataolg-original";
	fullpath = output + outputfile;
	saveAs("Jpeg", fullpath);
		
	if (plate_overlay==true){
		selectWindow("original");
		outputfile = title + "_original";
		fullpath = output + outputfile;
		saveAs("Jpeg", fullpath);
	
		selectWindow("labels");
		outputfile = title + "_labelled";
		fullpath = output + outputfile;
		saveAs("Jpeg", fullpath);
	}
	if (isOpen("ROI Manager")) {
		selectWindow("ROI Manager");
		run("Close");
	}
	if (isOpen("Results")) {
		selectWindow("Results");
		run("Close");
	}
	run("Close All");
}

/*end of macro*/