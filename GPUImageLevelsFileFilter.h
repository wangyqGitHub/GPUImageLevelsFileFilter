//
//  GPUImageLevelsFileFilter.m
//  Filter
//
//  Created by wangyq on 2018/3/30.
//  Copyright © 2018年 645884848@qq.com. All rights reserved.
//

#import <GPUImage/GPUImage.h>

@interface GPUImageLevelsFileFilter : GPUImageFilterGroup

/*
 * init filter with NSData
 */
- (id)initWithALVData:(NSData*)data;

/*
 * init filter with boundle file name
 */
- (id)initWithALV:(NSString*)filename;

/*
 * init filter with ALV source URL path
 */
- (id)initWithALVURL:(NSURL*)fileURL;

@end


