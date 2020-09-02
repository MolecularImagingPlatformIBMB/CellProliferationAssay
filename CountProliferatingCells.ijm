///////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Name: ki67_quantification.ijm
// Author: Elena Rebollo, Molecular Imaging Platform IBMB, Barcelona
// Date: 23/03/2017 /Modified december 2017/revisited 26 August 2020
/* Description: Count the number of GFP+ and GFP- nuclei, and the number of ki67 and PH3+ within each of the previous cathegories;
				It used a nuceli mask previously created; Delivers the counting results datasheet.xls and a verification image where 
				the nuclei have been outlined: GFP(-) in blue, GFP(+) in green, ki67(+) in red and PH3 in magenta*/
// Comments: created in Fiji lifeline 22 Dec 2015; 

// Instructions: 1. Run; 2. Select Folder to store results; 3. Open multichannel image; 4. Open binary mask; 5. Select background ROI when prompted.

///////////////////////////////////////////////////////////////////////////////////////////////////////////////


//CHOOSE RESULTS DIRECTORY AND OPEN IMAGE
MyDestinationFolder=getDirectory("Choose a folder to save results");
open(); //select multichannel image
rawName=getTitle;
getDisplayedArea(x, y, width, height);
open(); //select mask
rename("nucleiMask");

//PREPARE IMAGES 
prepareImages(rawName);
verificationImage("ki67", "gfp", "dapi", "PH3");

//SELECT ROI FOR BACKGROUND LEVEL & APPLY
selectWindow("verificationImage");
setTool("rectangle");
waitForUser("Select a ROI for background measurement");
roiManager("add");
BGGFP = measureROI("gfp");
BGki67 = measureROI("ki67");
BGPH3 = measureROI("PH3");

//OPEN NUCLEI MASK  & COUNT TOTAL NUMBER OF NUCLEI
selectWindow("nucleiMask");
run("Make Binary");
run("Options...", "iterations=1 count=1 do=Erode"); //objects are slightly eroded to avoid getting GFP signal from close nuclei
run("Analyze Particles...", "size=0-Infinity exclude clear add"); //the roi manage contains now all the possible nuclei
NoNuclei=roiManager("Count");

//SELECT [GFP+] and [GFP-], COUNT, CREATE MASKS & ADD TO VERIFICATION IMAGE
//All rois are loaded onto the roi manager
NoGFPplus=discardROIUnder("gfp", BGGFP, 4);
NoGFPminus=NoNuclei-NoGFPplus;
createMask("maskGFP+", width, height);
imageCalculator("Subtract create", "nucleiMask","maskGFP+");
rename("maskGFP-");
setForegroundColor(0, 255, 255);
paintROIs("verificationImage", "maskGFP-");
setForegroundColor(0, 255, 0);
paintROIs("verificationImage", "maskGFP+");

//SELECT [GFP+ki67+], COUNT & CREATE MASKS; GFP+ rois are at the ROI Manager
//GFP+ are loaded onto the roi manager
NoGFPpluski67plus=discardROIUnder("ki67", BGki67, 2.0); 
NoGFPpluski67minus=NoGFPplus-NoGFPpluski67plus;
createMask("maskGFP+ki67+", width, height);
run("Options...", "iterations=2 count=1 do=Erode");
setForegroundColor(255, 0, 0);
paintROIs("verificationImage", "maskGFP+ki67+"); //las GFP+ ki67+ eroded siguen en el roi manager para contar las ph3

//SELECT [GFP+ki67+PH3+],COUNT, CREATE MASK & ADD TO VERIFICATION IMAGE
//GFP+KI67* are loaded onto the roi manager 
NoGFPpluski67plusPH3plus=discardROIUnder("PH3", BGPH3, 5); 
createMask("maskGFP+ki67+PH3+", width, height);
run("Options...", "iterations=2 count=1 do=Erode");
setForegroundColor(255, 0, 229);
fillROIs("verificationImage", "maskGFP+ki67+PH3+"); 

//CLOSE ALL MASKS EXCEPT FOR GFP- 
close("nucleiMask");
//close("maskGFP+");
//close("maskGFP+ki67+");
//close("maskGFP+ki67+PH3+");

//SELECT [GFP-KI67+], COUNT, CREATE MASK AND ADD TO VERIFICATION IMAGE
// add GFP- rois to roi manager
selectWindow("maskGFP-");
roiManager("reset");
run("Analyze Particles...", "size=0-Infinity exclude clear add");
NoGFPminuski67plus=discardROIUnder("ki67", BGki67, 2.2); 
NoGFPminuski67minus=NoGFPminus-NoGFPminuski67plus;
createMask("maskGFP-ki67+", width, height);
run("Options...", "iterations=2 count=1 do=Erode");
setForegroundColor(255, 0, 0);
paintROIs("verificationImage", "maskGFP-ki67+"); 

//SELECT [GFP-ki67+PH3+], COUNT, CREATE MASK & ADD TO VERIFICATION IMAGE
// GFP-ki67+ are loaded onto the roi manager
// save verification image
NoGFPminuski67plusPH3plus=discardROIUnder("PH3", BGPH3, 3); 
createMask("maskGFP-ki67+PH3+", width, height);
run("Options...", "iterations=2 count=1 do=Erode");
setForegroundColor(255, 0, 229);
fillROIs("verificationImage", "maskGFP-ki67+PH3+");
saveAs("TIFF", MyDestinationFolder+"Verification_"+rawName);
//run("Close");

// CLOSE EXTRA WINDOWS
//close("maskGFP-ki67+PH3+");
//close("maskGFP-ki67+");
//close("maskGFP-");
close("Results");
close("gfp");
close("ki67");
close("PH3");
selectWindow("ROI Manager");
run("Close");

//CREATE RESULTS TABLE AS .XLS IN DESTINATION FOLDER
run("Table...", "name=[Results] width=400 height=300 menu");
print("[Results]", "\\Headings:"+" Image name \t Total Nuclei \t GFP(-) \t GFP(-) KI67(+) \t GFP(-) KI67 (+) PH3(+) \t GFP(+) \t GFP(+) KI67(+) \t GFP(+) KI67(+) PH3(+)");
print("[Results]", ""+rawName+"\t"+NoNuclei+"\t"+NoGFPminus+ "\t" + NoGFPminuski67plus + "\t" + NoGFPminuski67plusPH3plus + "\t" + NoGFPplus + "\t" + NoGFPpluski67plus + "\t" + NoGFPpluski67plusPH3plus+"");
selectWindow("Results");
saveAs("Text", MyDestinationFolder+"Results_"+rawName+".xls");
//run("Close");


///////// USER-DEFINED FUNCTIONS//////////////////

/*the prepareImages() function splits the channels, rename then and resets the min and max values of each one before convertion to 8-bits.
Fixing the upper and lower values for each channel (obviously to limits that exclude data cropping), will avoid changes in the relative 
intensities  due to linear convertion to 8-bits*/
function prepareImages(image){
	selectWindow(image);
	run("Split Channels");
	selectWindow("C4-"+image);
	setMinAndMax(150, 2095);
	run("8-bit");
	rename("PH3");
	selectWindow("C3-"+image);
	setMinAndMax(150, 4095);
	run("8-bit");
	rename("ki67");
	selectWindow("C2-"+image);
	setMinAndMax(200, 4095);
	run("8-bit");
	rename("gfp");
	selectWindow("C1-"+image);
	rename("dapi");
	setMinAndMax(680, 3095);
	run("8-bit");
	}

function verificationImage(image1, image2, image3, image4){
	run("Merge Channels...", "c1="+image1+" c2="+image2+" c3="+image3+" c4="+image4+" create keep");
	run("RGB Color");
	rename("verificationImage");
	close("Composite");
	close("dapi");
}

function measureROI(image){
	selectWindow(image);
	run("Set Measurements...", "area mean min integrated redirect=None decimal=2");
	roiManager("Measure");
	MeanROI = getResult("Mean", 0);
	run("Clear Results");
	return MeanROI
}

function discardROIUnder(image, ROIref, threshold){
	selectWindow(image);
	NoROI=roiManager("count");
	for(j=0; j<NoROI; j++){
		roiManager("Select", j);
		roiManager("Measure");
		ROIvalue=getResult("Mean", 0);
		cutOff=ROIvalue/ROIref;
		if(cutOff < threshold){
			roiManager("Delete");
			j--;
			NoROI--;
			}
		run("Clear Results");
		}
		NumROIFinal=roiManager("count");
		return NumROIFinal
}

function createMask(name, width, height) {
	newImage(name, "8-bit white", width, height, 1);
	setForegroundColor(0, 0, 0);
	roiManager("Deselect");
	roiManager("Fill");
	setOption("BlackBackground", false);
	run("Make Binary");
}

function paintROIs(image, mask){
	selectWindow(mask);
	roiManager("reset");
	run("Analyze Particles...", "size=0-Infinity exclude clear add");
	selectWindow(image);
	run("Line Width...", "line=2");
	roiManager("Deselect");
	roiManager("Draw");

}

function fillROIs(image, mask){
	selectWindow(mask);
	roiManager("reset");
	run("Analyze Particles...", "size=0-Infinity exclude clear add");
	selectWindow(image);
	roiManager("Deselect");
	roiManager("Fill");

}
