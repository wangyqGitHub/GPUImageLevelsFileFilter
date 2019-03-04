//
//  GPUImageLevelsFileFilter.m
//  Filter
//
//  Created by wangyq on 2018/3/30.
//  Copyright © 2018年 645884848@qq.com. All rights reserved.
//

#import "GPUImageLevelsFileFilter.h"

#pragma mark -
#pragma mark GPUImageALVFile Helper

struct GPULevelsOptions {
    short min;
    short max;
    short minOut;
    short maxOut;
    short gamma;
};

//  GPUImageALVFile
//
//  ALV File format Parser
//  Please refer to https://www.adobe.com/devnet-apps/photoshop/fileformatashtml/#50577411_pgfId-1057086
//

@interface GPUImageALVFile : NSObject{
    u_int8_t *start;
    u_int8_t *end;
    NSUInteger length;
    u_int8_t *cursor;
}

@property(nonatomic)struct GPULevelsOptions RGBLevels;
@property(nonatomic)struct GPULevelsOptions RedLevels;
@property(nonatomic)struct GPULevelsOptions GreenLevels;
@property(nonatomic)struct GPULevelsOptions BlueLevels;

- (id) initWithFileData:(NSData*)data;

@end

@implementation GPUImageALVFile

- (id) initWithFileData:(NSData*)data{
    self = [super init];
    if (self){

        if (data.length == 0){
            NSLog(@"failed to init ALV File with data:%@", data);
            return nil;
        }

        [self parseData:data];
        
        short theVersion = 0;
        if (![self scanEndiannessIntoShort:&theVersion] && theVersion != 2){
            NSLog(@"ALV data format error !");
            return nil;
        }

        //loop rgb and r\g\b channels
        NSMutableArray *arrayLevels = [NSMutableArray array];
        NSInteger channelsCount = 4;
        for (NSInteger m=0; m<channelsCount; m++) {
            struct GPULevelsOptions levels;
            [self scanEndiannessIntoShort:&levels.min];
            [self scanEndiannessIntoShort:&levels.max];
            [self scanEndiannessIntoShort:&levels.minOut];
            [self scanEndiannessIntoShort:&levels.maxOut];
            [self scanEndiannessIntoShort:&levels.gamma];

            NSValue *value = [NSValue value:&levels withObjCType:@encode(struct GPULevelsOptions)];
            [arrayLevels addObject:value];
        }
        struct GPULevelsOptions rgbLevels,redLevels,greenLevels,blueLevels ;
        [(NSValue *)arrayLevels[0] getValue:&rgbLevels];
        [(NSValue *)arrayLevels[1] getValue:&redLevels];
        [(NSValue *)arrayLevels[2] getValue:&greenLevels];
        [(NSValue *)arrayLevels[3] getValue:&blueLevels];

        self.RGBLevels = rgbLevels;
        self.RedLevels = redLevels;
        self.GreenLevels = greenLevels;
        self.BlueLevels = blueLevels;
    }

    return self;
}

- (void)parseData:(NSData *)inData{
    start = (u_int8_t *)inData.bytes;
    end = start + inData.length;
    length = inData.length;
    cursor = start;
}

- (BOOL)scanEndiannessIntoShort:(short *)outValue{
    const size_t theLength = sizeof(*outValue);
    if (end - cursor < theLength)  return NO;
    if (outValue){
        *outValue = EndianS16_BtoN(*(short *)cursor);
    }
    cursor += theLength;
    return YES;
}

@end

#pragma mark -
#pragma mark GPUImageLevelsFileFilter Implementation

@implementation GPUImageLevelsFileFilter

#pragma mark -
#pragma mark Initialization

- (id)initWithALVData:(NSData *)data {

    self = [super init];

    GPUImageALVFile *parser = [[GPUImageALVFile alloc] initWithFileData:data];

    if (!parser) return nil;

    // First pass: individual channels
    GPUImageLevelsFilter *individualChannelsFilter = [[GPUImageLevelsFilter alloc] init];
    [individualChannelsFilter setRedMin:normalizedRGBValues(parser.RedLevels.min) gamma:normalizedGammaValue(parser.RedLevels.gamma) max:normalizedRGBValues(parser.RedLevels.max) minOut:normalizedRGBValues(parser.RedLevels.minOut) maxOut:normalizedRGBValues(parser.RedLevels.maxOut)];
    [individualChannelsFilter setGreenMin:normalizedRGBValues(parser.GreenLevels.min) gamma:normalizedGammaValue(parser.GreenLevels.gamma) max:normalizedRGBValues(parser.GreenLevels.max) minOut:normalizedRGBValues(parser.GreenLevels.minOut) maxOut:normalizedRGBValues(parser.GreenLevels.maxOut)];
    [individualChannelsFilter setBlueMin:normalizedRGBValues(parser.BlueLevels.min) gamma:normalizedGammaValue(parser.BlueLevels.gamma) max:normalizedRGBValues(parser.BlueLevels.max) minOut:normalizedRGBValues(parser.BlueLevels.minOut) maxOut:normalizedRGBValues(parser.BlueLevels.maxOut)];
    [self addTarget:individualChannelsFilter];
    
    // Second pass: all channels
    GPUImageLevelsFilter *allChannelsFilter = [[GPUImageLevelsFilter alloc] init];
    [allChannelsFilter setMin:normalizedRGBValues(parser.RGBLevels.min) gamma:normalizedGammaValue(parser.RGBLevels.gamma) max:normalizedRGBValues(parser.RGBLevels.max) minOut:normalizedRGBValues(parser.RGBLevels.minOut) maxOut:normalizedRGBValues(parser.RGBLevels.maxOut)];
    [self addTarget:allChannelsFilter];
    
    [individualChannelsFilter addTarget:allChannelsFilter];
    
    self.initialFilters = [NSArray arrayWithObjects:individualChannelsFilter, nil];
    self.terminalFilter = allChannelsFilter;

    parser = nil;

    return self;
}

- (id)initWithALV:(NSString*)filename{
    return [self initWithALVURL:[[NSBundle mainBundle] URLForResource:filename withExtension:@"alv"]];
}

- (id)initWithALVURL:(NSURL*)fileURL{
    NSData *fileData = [NSData dataWithContentsOfURL:fileURL];
    return [self initWithALVData:fileData];
}

float normalizedRGBValues(float value) {
    return value/255.0;
}

float normalizedGammaValue(float value) {
    return value/100.0;
}

@end


