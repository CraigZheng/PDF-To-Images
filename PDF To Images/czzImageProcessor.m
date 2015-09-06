//
//  czzImageProcessor.m
//  PDF To Images
//
//  Created by Craig on 2/11/12.
//  Copyright (c) 2012 Craig. All rights reserved.
//

#import "czzImageProcessor.h"

@implementation czzImageProcessor
@synthesize delegate;

NSFileManager *fileManager;
NSMutableArray *pdfPaths; //an array that holds all the pdf paths
//NSMutableArray *processedFilePaths; //an array that holds both zipped files and cover files;
NSString *targetPath; //path to where to save, create a directory under this path, then save all file to this path
NSString *currentPath; //the full path to the currently processing PDF
NSString* status; //status, which might have infos on currently processing PDF
NSString* error;//errors, which might have infors on errors or other abnormal
NSPDFImageRep *pdfRep; //the currently selected nspdfimagerep
bool stop = NO;
int imageHeight; //default height would be 800, widht would be calculated accrodingly
int currentPage; //which page is it now?

//these parameters are used to help decide image qualities
//parameters
const NSInteger NORMAL_QUALITY = 0;
const NSInteger HIGH_QUALITY = 1;
//flags
NSInteger imageQuality = 0;
NSInteger imageFormat = NSJPEGFileType; //default image format is jpeg

-(id)init{
    self = [super init];
    if (self){
        fileManager = [NSFileManager defaultManager];
       // imageHeight = 800;
        pdfPaths = [[NSMutableArray alloc]init];
        status = @"";
        error = @"";
    }
    return self;
}

//specify the path to the file, and save to where
-(void)setPDFPaths:(NSArray*)paths toPath:(NSString *)toPath{
    //make sure arrays are clear
    [pdfPaths removeAllObjects];
    NSAlert *alert = [[NSAlert alloc]init];
    [alert setAlertStyle:NSWarningAlertStyle];
    if (paths != nil){
        NSMutableArray *errorPath = [[NSMutableArray alloc]init];
        for (NSString *path in paths){
            if(![fileManager fileExistsAtPath:path]){
                [errorPath addObject:path];
            } else{
                [pdfPaths addObject:path];
            }
        }
        if (errorPath.count > 0){
            NSString *message = @"";
            for (NSString* faultyPath in errorPath){
                [message stringByAppendingString:@"\n"];
                [message stringByAppendingString: faultyPath];
            }
            [alert setMessageText:[NSString stringWithFormat:@"The following file(s) apears to be broken: \n%@", message]];
            [alert runModal];
            return;
        }
    } else {
        [alert setMessageText:@"File path is empty!"];
        [alert runModal];
        return;
    }
    //set up target path
    targetPath = toPath ;
}

//specify the height, optional
-(void)setImageHeight:(NSInteger)height{
    //sometimes people would love to specify their own height
    if(height >= 1)
        imageHeight = (int)height;
}

//specify the image format of images, optional
-(void)setImageFormat:(NSInteger)formatCode{
    if (formatCode == NSJPEGFileType || formatCode == NSPNGFileType)
        imageFormat = formatCode;
}

//specify the image quality, optional
-(void)setImageQuality:(NSInteger)qualityCode{
    if (qualityCode == NORMAL_QUALITY || qualityCode == HIGH_QUALITY)
        imageQuality = qualityCode;
}

//loop through all pdf paths
-(void)startTheConversion{
    if (pdfPaths.count == 0){
        NSLog(@"empty paths");
        return;
    }
    //this intensive work will likely block the ui, so don't do it in the ui thread
    for (NSString* path in pdfPaths){
        [self ConvertEachPath:path];
    }
    status = @"All conversions are finished!";
}

//for each path, begin the conversion and resizing
-(void)ConvertEachPath:(NSString*) pdfPath{
    if (pdfPath != nil){
        currentPath = pdfPath; //currently processing full path
        NSString *comicName = [[pdfPath lastPathComponent]stringByDeletingPathExtension];
        NSString *localTargetPath = [targetPath stringByAppendingPathComponent:comicName];
        //currently processing what?
        status = [NSString stringWithFormat:@"Reading: %@", comicName];
        [self.delegate conversionProgressFor:[currentPath lastPathComponent] status:@"Reading..." progress:0];
        NSError *error;
        [fileManager createDirectoryAtPath:localTargetPath withIntermediateDirectories:YES attributes:nil error:&error];
        if (error != nil){
            NSLog(@"WTF buddy error = %@", [error description]);
            return;
        }
        [self makeCover:currentPath]; //make a cover from the given pdf path
        pdfRep = [[NSPDFImageRep alloc]initWithData:[NSData dataWithContentsOfFile:pdfPath]]; //the actual PDF itself
        currentPage = 0; //begin with the first page
        [pdfRep setCurrentPage:currentPage];
        
        for (int i = 0; i < pdfRep.pageCount; i++){
            NSInteger percentage = (int)(((float)(currentPage+1)/(float)pdfRep.pageCount) * 100);
            //NSLog(@"%@", [NSString stringWithFormat:@"Processing: %@ - %ld%%", comicName, percentage]);
            [self.delegate conversionProgressFor:[currentPath lastPathComponent] status:@"Converting..." progress:percentage];
            if (stop){//if the user wants to stop the conversion mid-way
                return;
            }
            currentPage = i; 
            NSImage *image = [[NSImage alloc]initWithSize:pdfRep.size]; //NSImage that we will use to hold the picture
            [image setCacheMode:NSImageCacheNever];
            @try {
                [pdfRep setCurrentPage:i];
                [image setSize:pdfRep.size];
                [image addRepresentation:pdfRep];
                image = [self resizeNSImage:image newHeight:imageHeight];
                NSBitmapImageRep *bitmapRep = [NSBitmapImageRep imageRepWithData:[image TIFFRepresentation]]; //convert NSImage to NSBitmapImageRep for file output
                //decide the image quality and image format
                float compressFactor = 0.5; //default compress factor
                NSString *surfix = @"jpg"; //the file extension
                if (imageQuality == HIGH_QUALITY)
                    compressFactor = 0.8f; //high quality compress factor
                if (imageFormat == NSPNGFileType)
                    surfix = @"png"; //the file extension changed to png
                NSData *bitmapData = [bitmapRep representationUsingType:imageFormat properties:[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:compressFactor]    forKey:@"NSImageCompressionFactor"]];
                NSString *prefix = @"000";
                if (pdfRep.currentPage >= 9) //shrink the prefix accordingly
                    prefix = @"00"; if (pdfRep.currentPage >= 99) prefix = @"0";
                if ([bitmapData writeToFile:[NSString stringWithFormat:@"%@/%@%@%ld.%@",localTargetPath, [[pdfPath lastPathComponent]stringByDeletingPathExtension],prefix, (pdfRep.currentPage+1), surfix] atomically:YES]){
                } else
                    NSLog(@"File saving failed : %@", [NSString stringWithFormat:@"%@/%@%@%ld.%@",localTargetPath, [[pdfPath lastPathComponent]stringByDeletingPathExtension],prefix, (pdfRep.currentPage+1), surfix]);
            }
            @catch (NSException *exception) {
                NSString *errorReport = [NSString stringWithFormat:@"Failed: %d of %@", currentPage, currentPath];
                error = [NSString stringWithFormat:@"\n%@\n%@", error, errorReport];//retain the old status info, add new ones
            }
            [image removeRepresentation:pdfRep]; //remove the retained pdfRep

        }
        //after the PDF conversion, zip the newly added folder
        [self zipTheGivenFolder:localTargetPath];
    }
}

//zip folders with in given path
-(void)zipTheGivenFolder:(NSString*)folderPath{
    if (folderPath != nil){
        NSString *filename = [folderPath lastPathComponent];
        status = [NSString stringWithFormat:@"Zipping: %@", filename];
        [self.delegate conversionProgressFor:filename status:@"Zipping..." progress:100];
        NSString *targetZipPath = [folderPath stringByAppendingPathExtension:@"zip"];

		
        //NSArray *args = [NSArray arrayWithObjects:@"-r", @"-j", targetZipPath, folderPath, nil];
        NSArray *args = [NSArray arrayWithObjects:@"-c", @"-k", @"--sequesterRsrc", @"--keepParent", folderPath, targetZipPath, nil];
        //invoke system's zip archive to make a zip file with the given folder
        NSTask *task = [[NSTask alloc] init];
        [task setLaunchPath:@"/usr/bin/ditto"];
        [task setArguments:args];
        [task setStandardOutput:[NSPipe pipe]];
        [task launch];
        [task waitUntilExit];
         
          //ditto -c -k --sequesterRsrc --keepParent src_directory archive.zip
          
        status = [NSString stringWithFormat:@"%@ is done!", filename];
        [self.delegate conversionProgressFor:filename status:@"Done!" progress:100];
        //inform delegate object that a file is ready, pass this file to delegate
        [self.delegate fileReady:targetZipPath];
    }
}

//make cover form the given pdfpath
-(void)makeCover:(NSString*)pdfPath{
    NSImage *coverImage = [[NSImage alloc]initWithContentsOfFile:pdfPath];
    NSString *comicName = [[pdfPath lastPathComponent]stringByDeletingPathExtension];
    NSString *coverTargetPath = [[targetPath stringByAppendingPathComponent:comicName] stringByAppendingPathExtension:@"jpg"];
    if (coverImage != nil){
        coverImage = [self resizeNSImage:coverImage newHeight:480];
        NSBitmapImageRep *bitmapRep = [NSBitmapImageRep imageRepWithData:[coverImage TIFFRepresentation]]; // conver the cover image to bitmapimagerep
        NSData *bitmapData = [bitmapRep representationUsingType:NSJPEGFileType properties:[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:0.5f]    forKey:@"NSImageCompressionFactor"]];
        [bitmapData writeToFile:coverTargetPath atomically:YES];
        //inform delegate object that this file is ready
        [self.delegate fileReady:coverTargetPath];
    }
}

//copy from internet, resize a nsimage by putting it inside a imageview
-(NSImage*) resizeNSImage:(NSImage*)aImage newHeight:(CGFloat)newHeight
{
    @autoreleasepool {
        CGFloat newWidth = aImage.size.width * (newHeight / aImage.size.height); //calculate the new width base on new height
        NSImageView* kView = [[NSImageView alloc] initWithFrame:NSMakeRect(0, 0, newWidth, newHeight)];
        [kView setImageScaling:NSImageScaleProportionallyUpOrDown];
        [kView setImage:aImage];
        
        NSRect kRect = kView.frame;
        NSBitmapImageRep* kRep = [kView bitmapImageRepForCachingDisplayInRect:kRect];
        [kView cacheDisplayInRect:kRect toBitmapImageRep:kRep];
        
        NSData* kData = [kRep representationUsingType:NSJPEGFileType properties:nil];
        return [[NSImage alloc] initWithData:kData];
    }
}

//return the current status
-(NSString *)getStatus{
    return status;
}

//return the current progress in percentage
//key - value set: full path - percentage
//the calculation of percentage is its total pagecount divide by current page
-(NSDictionary*)getCurrentProgress{
    //NSLog(@"%d / %ld", currentPage, pdfRep.pageCount);
    int percentage = ((float)(currentPage+1)/(float)pdfRep.pageCount) * 100;
    NSDictionary *dict = [NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"%d", percentage] forKey:currentPath];
    //NSLog(@"current percentage = %d, for key %@", percentage, currentPath);
    return dict;
}

//get all processed files - including zip files and cover files - discarded
-(NSArray *)getProcessedFilePaths{
    //return processedFilePaths;
    return nil;
}

//return errors
-(NSString *)getError{
    return error;
}
@end
