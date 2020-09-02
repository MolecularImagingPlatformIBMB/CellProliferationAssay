///////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Name: Nuclei Segmentation with Manual Correction
// Author: Elena Rebollo, Moñecular Imaging Platform IBMB, Barcelona
// Date: 13/03/2017, revisited 26/08/2020
/* Description: Segments nuclei based on local contrast & local thresholding, and allows for manually correcting the resulting 
   mask by painting separation lines on the dapi image, and selecting ROIs to merge/delete on the binary mask; it saves the
   resulting mask to the selected folder using the original name plus "nucleiMask_" */
// Comment: created in Fiji lifeline 22 Dec 2015
/* Instructions: 1. Run; 2. Select folder to store mask; 3. Select multichannel image (the function prepareImages() 
                     must be adapted to the particular channel distribution)*/

///////////////////////////////////////////////////////////////////////////////////////////////////////////////

//CHOOSE RESULTS DIRECTORY, OPEN IMAGE & GET INFO
MyDestinationFolder=getDirectory("Choose a folder to save results");
open(); //select multichannel image
rawName=getTitle();
getDisplayedArea(x, y, width, height);

//PREPARE DAPI CAHNNEL
prepareImages(rawName);

//SEGMENT DAPI CHANNEL
//Enhance local contrast
run("Enhance Local Contrast (CLAHE)", "blocksize=100 histogram=100 maximum=3 mask=*None*");
run("Gaussian Blur...", "sigma=2");
//thresholding
setAutoThreshold("Otsu dark");
setOption("BlackBackground", false);
run("Convert to Mask");
run("Make Binary");
run("Watershed");
//Load onto ROI Manager
run("Analyze Particles...", "size=25-Infinity exclude clear add");

//CORRECT SEGMENTATION ON THE BINARY MASK
Correction = true;
while(Correction) ¨{
GoOn = true;
run("Line Width...", "line=2");
setTool("line");
setTool("freeline");
while(GoOn) {
	selectWindow("maskOfDapi");
	roiManager("Show None");
	waitForUser("Paint separation line");
	GoOn =  (selectionType()==7);
	if (GoOn == true) {
	selectWindow("maskOfDapi");
	run("Restore Selection");
	setForegroundColor(255,255,255);
	run("Line to Area");
	run("Fill", "slice");
	run("Select None");
	}
	GoOn = getNumber("Go on?", 1);
}
GoOn = true;
setTool("wand");
while(GoOn) {
	selectWindow("maskOfDapi");
	waitForUser("Select two ROIs to combine");
	GoOn =  (selectionType()==9);
	if (GoOn == true) {
	run("Enlarge...", "enlarge=1");
	run("Enlarge...", "enlarge=-1");
	setForegroundColor(0,0,0);
	run("Fill", "slice");
	run("Select None");
	}
	GoOn = getNumber("Go on?", 1);
} 
GoOn = true;
setTool("wand");
while(GoOn) {
	selectWindow("maskOfDapi");
	waitForUser("Select ROI to delete");
	GoOn =  (selectionType()==4);
	if (GoOn == true) {
	setForegroundColor(255,255,255);
	run("Fill", "slice");
	run("Select None");
	}
	GoOn = getNumber("Go on?", 1);
} 
roiManager("deselect");
roiManager("reset");
selectWindow("maskOfDapi");
run("Select All");
run("Analyze Particles...", "size=20-Infinity exclude clear add");
waitForUser("Check segmentation");
Correction = getNumber("More correction needed?", 1);
}

//CREATE MASK, RENAME & SAVE
createMask("nucleiMask_"+rawName, width, height);
run("Options...", "iterations=1 count=1 do=Erode");
saveAs("TIFF", MyDestinationFolder+"nucleiMask_"+rawName);
run("Close");

//CLOSE WINDOWS
close("maskOfDapi");
close("dapi");
selectWindow("ROI Manager");
run("Close");

////// USER-DEFINED FUNCTIONS /////////////////////////////

function prepareImages(image){
	selectWindow(image);
	run("Split Channels");
	close("C4-"+image);
	close("C3-"+image);
	setMinAndMax(150, 4095);
	close("C2-"+image);
	selectWindow("C1-"+image);
	rename("dapi");
	run("8-bit");
	run("Fire");
	run("Duplicate...", "title=maskOfDapi");
	}
	
function createMask(name, width, height) {
	newImage(name, "8-bit white", width, height, 1);
	setForegroundColor(0, 0, 0);
	roiManager("Deselect");
	roiManager("Fill");
	setOption("BlackBackground", false);
	run("Make Binary");
}




