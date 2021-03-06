//
//  CFTool.m
//  DemoSet
//
//  Created by CaoFeng on 2017/4/21.
//  Copyright © 2017年 深圳中业兴融互联网金融服务有限公司. All rights reserved.
//

#define kUUID @"dvadsbvoodcodvcd"
#define kUUIDValue @"baohdnvpiupqfhwfdbvhbdva"

#import "CFTool.h"
#include <sys/sysctl.h>
#import <CommonCrypto/CommonDigest.h> // Need to import for CC_MD5 access
#import <AdSupport/ASIdentifierManager.h>
#import <sys/utsname.h>
#import "SAMKeychain.h"


@implementation CFTool

//磁盘总空间
+ (CGFloat)diskOfAllSizeMBytes{
    CGFloat size = 0.0;
    NSError *error;
    NSDictionary *dic = [[NSFileManager defaultManager] attributesOfFileSystemForPath:NSHomeDirectory() error:&error];
    if (error) {
#ifdef DEBUG
        NSLog(@"error: %@", error.localizedDescription);
#endif
    }else{
        NSNumber *number = [dic objectForKey:NSFileSystemSize];
        size = [number floatValue]/1024/1024;
    }
    return size;
}
//磁盘可用空间
+ (CGFloat)diskOfFreeSizeMBytes{
    CGFloat size = 0.0;
    NSError *error;
    NSDictionary *dic = [[NSFileManager defaultManager] attributesOfFileSystemForPath:NSHomeDirectory() error:&error];
    if (error) {
#ifdef DEBUG
        NSLog(@"error: %@", error.localizedDescription);
#endif
    }else{
        NSNumber *number = [dic objectForKey:NSFileSystemFreeSize];
        size = [number floatValue]/1024/1024;
    }
    return size;
}
//获取文件大小
+ (long long)fileSizeAtPath:(NSString *)filePath{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:filePath]) return 0;
    return [[fileManager attributesOfItemAtPath:filePath error:nil] fileSize];
}
//获取文件夹下所有文件的大小
+ (long long)folderSizeAtPath:(NSString *)folderPath{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:folderPath]) return 0;
    NSEnumerator *filesEnumerator = [[fileManager subpathsAtPath:folderPath] objectEnumerator];
    NSString *fileName;
    long long folerSize = 0;
    while ((fileName = [filesEnumerator nextObject]) != nil) {
        NSString *filePath = [folderPath stringByAppendingPathComponent:fileName];
        folerSize += [self fileSizeAtPath:filePath];
    }
    return folerSize;
}
//获取字符串(或汉字)首字母
+ (NSString *)firstCharacterWithString:(NSString *)string{
    NSMutableString *str = [NSMutableString stringWithString:string];
    CFStringTransform((CFMutableStringRef)str, NULL, kCFStringTransformMandarinLatin, NO);
    CFStringTransform((CFMutableStringRef)str, NULL, kCFStringTransformStripDiacritics, NO);
    NSString *pingyin = [str capitalizedString];
    return [pingyin substringToIndex:1];
}

/** 当前系统的准确时间
 *  @brief 当前时间
 *  @return 当前时间
 */
+ (NSDate *)getNowTime{
    NSDate *date = [NSDate date]; // 获得时间对象
    NSTimeZone *zone = [NSTimeZone systemTimeZone]; // 获得系统的时区
    NSTimeInterval time = [zone secondsFromGMTForDate:date];// 以秒为单位返回当前时间与系统格林尼治时间的差
    return [date dateByAddingTimeInterval:time];// 然后把差的时间加上,就是当前系统准确的时间
}

//获取当前时间
//format: @"yyyy-MM-dd HH:mm:ss"、@"yyyy年MM月dd日 HH时mm分ss秒"
+ (NSString *)currentDateWithFormat:(NSString *)format{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:format];
    return [dateFormatter stringFromDate:[NSDate date]];
}
/**
 *  计算上次日期距离现在多久
 *
 *  @param lastTime    上次日期(需要和格式对应)
 *  @param format1     上次日期格式
 *  @param currentTime 最近日期(需要和格式对应)
 *  @param format2     最近日期格式
 *
 *  @return xx分钟前、xx小时前、xx天前
 */
+ (NSString *)timeIntervalFromLastTime:(NSString *)lastTime
                        lastTimeFormat:(NSString *)format1
                         ToCurrentTime:(NSString *)currentTime
                     currentTimeFormat:(NSString *)format2{
    //上次时间
    NSDateFormatter *dateFormatter1 = [[NSDateFormatter alloc]init];
    dateFormatter1.dateFormat = format1;
    NSDate *lastDate = [dateFormatter1 dateFromString:lastTime];
    //当前时间
    NSDateFormatter *dateFormatter2 = [[NSDateFormatter alloc]init];
    dateFormatter2.dateFormat = format2;
    NSDate *currentDate = [dateFormatter2 dateFromString:currentTime];
    return [CFTool timeIntervalFromLastTime:lastDate ToCurrentTime:currentDate];
}

+ (NSString *)timeIntervalFromLastTime:(NSDate *)lastTime ToCurrentTime:(NSDate *)currentTime{
    NSTimeZone *timeZone = [NSTimeZone systemTimeZone];
    //上次时间
    NSDate *lastDate = [lastTime dateByAddingTimeInterval:[timeZone secondsFromGMTForDate:lastTime]];
    //当前时间
    NSDate *currentDate = [currentTime dateByAddingTimeInterval:[timeZone secondsFromGMTForDate:currentTime]];
    //时间间隔
    NSInteger intevalTime = [currentDate timeIntervalSinceReferenceDate] - [lastDate timeIntervalSinceReferenceDate];
    
    //秒、分、小时、天、月、年
    NSInteger minutes = intevalTime / 60;
    NSInteger hours = intevalTime / 60 / 60;
    NSInteger day = intevalTime / 60 / 60 / 24;
    NSInteger month = intevalTime / 60 / 60 / 24 / 30;
    NSInteger yers = intevalTime / 60 / 60 / 24 / 365;
    
    if (minutes <= 10) {
        return  @"刚刚";
    }else if (minutes < 60){
        return [NSString stringWithFormat: @"%ld分钟前",(long)minutes];
    }else if (hours < 24){
        return [NSString stringWithFormat: @"%ld小时前",(long)hours];
    }else if (day < 30){
        return [NSString stringWithFormat: @"%ld天前",(long)day];
    }else if (month < 12){
        NSDateFormatter * df =[[NSDateFormatter alloc]init];
        df.dateFormat = @"M月d日";
        NSString * time = [df stringFromDate:lastDate];
        return time;
    }else if (yers >= 1){
        NSDateFormatter * df =[[NSDateFormatter alloc]init];
        df.dateFormat = @"yyyy年M月d日";
        NSString * time = [df stringFromDate:lastDate];
        return time;
    }
    return @"";
}
//判断手机号码格式是否正确
+ (BOOL)valiMobile:(NSString *)mobile{
    mobile = [mobile stringByReplacingOccurrencesOfString:@" " withString:@""];
    if (mobile.length != 11)
    {
        return NO;
    }else{
        /**
         * 移动号段正则表达式
         */
        NSString *CM_NUM = @"^((13[4-9])|(147)|(15[0-2,7-9])|(178)|(18[2-4,7-8]))\\d{8}|(1705)\\d{7}$";
        /**
         * 联通号段正则表达式
         */
        NSString *CU_NUM = @"^((13[0-2])|(145)|(15[5-6])|(176)|(18[5,6]))\\d{8}|(1709)\\d{7}$";
        /**
         * 电信号段正则表达式
         */
        NSString *CT_NUM = @"^((133)|(153)|(177)|(18[0,1,9]))\\d{8}$";
        NSPredicate *pred1 = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", CM_NUM];
        BOOL isMatch1 = [pred1 evaluateWithObject:mobile];
        NSPredicate *pred2 = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", CU_NUM];
        BOOL isMatch2 = [pred2 evaluateWithObject:mobile];
        NSPredicate *pred3 = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", CT_NUM];
        BOOL isMatch3 = [pred3 evaluateWithObject:mobile];
        
        if (isMatch1 || isMatch2 || isMatch3) {
            return YES;
        }else{
            return NO;
        }
    }
}
//利用正则表达式验证
//判断邮箱格式是否正确
+ (BOOL)isAvailableEmail:(NSString *)email {
    NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    return [emailTest evaluateWithObject:email];
}
//将十六进制颜色转换为 UIColor 对象
+ (UIColor *)colorWithHexString:(NSString *)color{
    
    return [CFTool colorWithHexString:color alpha:1.0f];
}

+ (UIColor *)colorWithHexString:(NSString *)color alpha:(CGFloat)alpha {
    
    NSString *cString = [[color stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];
    // String should be 6 or 8 characters
    if ([cString length] < 6) {
        return [UIColor clearColor];
    }
    // strip "0X" or "#" if it appears
    if ([cString hasPrefix:@"0X"])
        cString = [cString substringFromIndex:2];
    if ([cString hasPrefix:@"#"])
        cString = [cString substringFromIndex:1];
    if ([cString length] != 6)
        return [UIColor clearColor];
    // Separate into r, g, b substrings
    NSRange range;
    range.location = 0;
    range.length = 2;
    //r
    NSString *rString = [cString substringWithRange:range];
    //g
    range.location = 2;
    NSString *gString = [cString substringWithRange:range];
    //b
    range.location = 4;
    NSString *bString = [cString substringWithRange:range];
    // Scan values
    unsigned int r, g, b;
    [[NSScanner scannerWithString:rString] scanHexInt:&r];
    [[NSScanner scannerWithString:gString] scanHexInt:&g];
    [[NSScanner scannerWithString:bString] scanHexInt:&b];
    return [UIColor colorWithRed:((float) r / 255.0f) green:((float) g / 255.0f) blue:((float) b / 255.0f) alpha:alpha];
}


#pragma mark - 对图片进行滤镜处理
// 怀旧 --> CIPhotoEffectInstant                         单色 --> CIPhotoEffectMono
// 黑白 --> CIPhotoEffectNoir                            褪色 --> CIPhotoEffectFade
// 色调 --> CIPhotoEffectTonal                           冲印 --> CIPhotoEffectProcess
// 岁月 --> CIPhotoEffectTransfer                        铬黄 --> CIPhotoEffectChrome
// CILinearToSRGBToneCurve, CISRGBToneCurveToLinear, CIGaussianBlur, CIBoxBlur, CIDiscBlur, CISepiaTone, CIDepthOfField
+ (UIImage *)filterWithOriginalImage:(UIImage *)image filterName:(NSString *)name{
    CIContext *context = [CIContext contextWithOptions:nil];
    CIImage *inputImage = [[CIImage alloc] initWithImage:image];
    CIFilter *filter = [CIFilter filterWithName:name];
    [filter setValue:inputImage forKey:kCIInputImageKey];
    CIImage *result = [filter valueForKey:kCIOutputImageKey];
    CGImageRef cgImage = [context createCGImage:result fromRect:[result extent]];
    UIImage *resultImage = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);
    return resultImage;
}
#pragma mark - 对图片进行模糊处理
// CIGaussianBlur ---> 高斯模糊
// CIBoxBlur      ---> 均值模糊(Available in iOS 9.0 and later)
// CIDiscBlur     ---> 环形卷积模糊(Available in iOS 9.0 and later)
// CIMedianFilter ---> 中值模糊, 用于消除图像噪点, 无需设置radius(Available in iOS 9.0 and later)
// CIMotionBlur   ---> 运动模糊, 用于模拟相机移动拍摄时的扫尾效果(Available in iOS 9.0 and later)
+ (UIImage *)blurWithOriginalImage:(UIImage *)image blurName:(NSString *)name radius:(NSInteger)radius{
    CIContext *context = [CIContext contextWithOptions:nil];
    CIImage *inputImage = [[CIImage alloc] initWithImage:image];
    CIFilter *filter;
    if (name.length != 0) {
        filter = [CIFilter filterWithName:name];
        [filter setValue:inputImage forKey:kCIInputImageKey];
        if (![name isEqualToString:@"CIMedianFilter"]) {
            [filter setValue:@(radius) forKey:@"inputRadius"];
        }
        CIImage *result = [filter valueForKey:kCIOutputImageKey];
        CGImageRef cgImage = [context createCGImage:result fromRect:[result extent]];
        UIImage *resultImage = [UIImage imageWithCGImage:cgImage];
        CGImageRelease(cgImage);
        return resultImage;
    }else{
        return nil;
    }
}
/**
 *  调整图片饱和度, 亮度, 对比度
 *
 *  @param image      目标图片
 *  @param saturation 饱和度
 *  @param brightness 亮度: -1.0 ~ 1.0
 *  @param contrast   对比度
 *
 */
+ (UIImage *)colorControlsWithOriginalImage:(UIImage *)image
                                 saturation:(CGFloat)saturation
                                 brightness:(CGFloat)brightness
                                   contrast:(CGFloat)contrast{
    CIContext *context = [CIContext contextWithOptions:nil];
    CIImage *inputImage = [[CIImage alloc] initWithImage:image];
    CIFilter *filter = [CIFilter filterWithName:@"CIColorControls"];
    [filter setValue:inputImage forKey:kCIInputImageKey];
    
    [filter setValue:@(saturation) forKey:@"inputSaturation"];
    [filter setValue:@(brightness) forKey:@"inputBrightness"];
    [filter setValue:@(contrast) forKey:@"inputContrast"];
    
    CIImage *result = [filter valueForKey:kCIOutputImageKey];
    CGImageRef cgImage = [context createCGImage:result fromRect:[result extent]];
    UIImage *resultImage = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);
    return resultImage;
}
//Avilable in iOS 8.0 and later
//创建一张实时模糊效果 View (毛玻璃效果)
+ (UIVisualEffectView *)effectViewWithFrame:(CGRect)frame{
    UIBlurEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
    UIVisualEffectView *effectView = [[UIVisualEffectView alloc] initWithEffect:effect];
    effectView.frame = frame;
    return effectView;
}
//全屏截图
+ (UIImage *)shotScreen{
    
    
    
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    UIGraphicsBeginImageContext(window.bounds.size);
    [window.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}
//截取view生成一张图片
+ (UIImage *)shotWithView:(UIView *)view{
    UIGraphicsBeginImageContext(view.bounds.size);
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}
//截取view中某个区域生成一张图片
+ (UIImage *)shotWithView:(UIView *)view scope:(CGRect)scope{
    CGImageRef imageRef = CGImageCreateWithImageInRect([self shotWithView:view].CGImage, scope);
    UIGraphicsBeginImageContext(scope.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGRect rect = CGRectMake(0, 0, scope.size.width, scope.size.height);
    CGContextTranslateCTM(context, 0, rect.size.height);//下移
    CGContextScaleCTM(context, 1.0f, -1.0f);//上翻
    CGContextDrawImage(context, rect, imageRef);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    CGImageRelease(imageRef);
    CGContextRelease(context);
    return image;
}
//压缩图片到指定尺寸大小
+ (UIImage *)compressOriginalImage:(UIImage *)image toSize:(CGSize)size{
    UIImage *resultImage = image;
    UIGraphicsBeginImageContext(size);
    [resultImage drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIGraphicsEndImageContext();
    return resultImage;
}
//压缩图片到指定文件大小
+ (NSData *)compressOriginalImage:(UIImage *)image toMaxDataSizeKBytes:(CGFloat)size{
    NSData *data = UIImageJPEGRepresentation(image, 1.0);
    CGFloat dataKBytes = data.length/1000.0;
    CGFloat maxQuality = 0.9f;
    CGFloat lastData = dataKBytes;
    while (dataKBytes > size && maxQuality > 0.01f) {
        maxQuality = maxQuality - 0.01f;
        data = UIImageJPEGRepresentation(image, maxQuality);
        dataKBytes = data.length/1000.0;
        if (lastData == dataKBytes) {
            break;
        }else{
            lastData = dataKBytes;
        }
    }
    return data;
}
/**
 *  判断名称是否合法
 *  @param name 名称
 *  @return yes / no
 */
+ (BOOL)isNameValid:(NSString *)name
{
    BOOL isValid = NO;
    
    if (name.length > 0)
    {
        for (NSInteger i=0; i<name.length; i++)
        {
            unichar chr = [name characterAtIndex:i];
            
            if (chr < 0x80)
            { //字符
                if (chr >= 'a' && chr <= 'z')
                {
                    isValid = YES;
                }
                else if (chr >= 'A' && chr <= 'Z')
                {
                    isValid = YES;
                }
                else if (chr >= '0' && chr <= '9')
                {
                    isValid = YES;
                }
                else if (chr == '-' || chr == '_')
                {
                    isValid = YES;
                }
                else
                {
                    isValid = NO;
                }
            }
            else if (chr >= 0x4e00 && chr < 0x9fa5)
            { //中文
                isValid = YES;
            }
            else
            { //无效字符
                isValid = NO;
            }
            
            if (!isValid)
            {
                break;
            }
        }
    }
    
    return isValid;
}
//判断字符串是否含有中文
+ (BOOL)isHaveChineseInString:(NSString *)string{
    for(NSInteger i = 0; i < [string length]; i++){
        int a = [string characterAtIndex:i];
        if (a > 0x4e00 && a < 0x9fff) {
            return YES;
        }
    }
    return NO;
}
//判断字符串是否全部为数字
+ (BOOL)isAllNum:(NSString *)string{
    unichar c;
    for (int i=0; i<string.length; i++) {
        c=[string characterAtIndex:i];
        if (!isdigit(c)) {
            return NO;
        }
    }
    return YES;
}
/*  绘制虚线
 ** lineFrame:     虚线的 frame
 ** length:        虚线中短线的宽度
 ** spacing:       虚线中短线之间的间距
 ** color:         虚线中短线的颜色
 */
+ (UIView *)createDashedLineWithFrame:(CGRect)lineFrame
                           lineLength:(int)length
                          lineSpacing:(int)spacing
                            lineColor:(UIColor *)color{
    UIView *dashedLine = [[UIView alloc] initWithFrame:lineFrame];
    dashedLine.backgroundColor = [UIColor clearColor];
    CAShapeLayer *shapeLayer = [CAShapeLayer layer];
    [shapeLayer setBounds:dashedLine.bounds];
    [shapeLayer setPosition:CGPointMake(CGRectGetWidth(dashedLine.frame) / 2, CGRectGetHeight(dashedLine.frame))];
    [shapeLayer setFillColor:[UIColor clearColor].CGColor];
    [shapeLayer setStrokeColor:color.CGColor];
    [shapeLayer setLineWidth:CGRectGetHeight(dashedLine.frame)];
    [shapeLayer setLineJoin:kCALineJoinRound];
    [shapeLayer setLineDashPattern:[NSArray arrayWithObjects:[NSNumber numberWithInt:length], [NSNumber numberWithInt:spacing], nil]];
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, NULL, 0, 0);
    CGPathAddLineToPoint(path, NULL, CGRectGetWidth(dashedLine.frame), 0);
    [shapeLayer setPath:path];
    CGPathRelease(path);
    [dashedLine.layer addSublayer:shapeLayer];
    return dashedLine;
}

+ (NSMutableAttributedString *)mergeWithFirstString:(NSString *)firstString
                                    firstStringFont:(UIFont *)firstStringFont
                                       secondString:(NSString *)secondString
                                   secondStringFont:(UIFont *)secondStringFont {
    
    return [CFTool mergeWithFirstString:firstString
                              firstStringFont:firstStringFont
                             firstStringColor:nil
                                 secondString:secondString
                             secondStringFont:secondStringFont
                            secondStringColor:nil];
}

+ (NSMutableAttributedString *)mergeWithFirstString:(NSString *)firstString
                                    firstStringFont:(UIFont *)firstStringFont
                                   firstStringColor:(UIColor *)firstStringColor
                                       secondString:(NSString *)secondString
                                   secondStringFont:(UIFont *)secondStringFont
                                  secondStringColor:(UIColor *)secondStringColor {
    
    NSMutableAttributedString *attribute = [[NSMutableAttributedString alloc]init];
    if (firstString) {
        NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
        if (firstStringFont) {
            attributes[NSFontAttributeName] = firstStringFont;
        }
        if (firstStringColor) {
            attributes[NSForegroundColorAttributeName] = firstStringColor;
        }
        
        NSAttributedString *firstStringAttr = [[NSAttributedString alloc] initWithString:firstString attributes:attributes];
        [attribute appendAttributedString:firstStringAttr];
    }
    
    if (secondString) {
        NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
        if (secondStringFont) {
            attributes[NSFontAttributeName] = secondStringFont;
        }
        if (secondStringColor) {
            attributes[NSForegroundColorAttributeName] = secondStringColor;
        }
        
        NSAttributedString *secondStringAttr = [[NSAttributedString alloc] initWithString:secondString attributes:attributes];
        [attribute appendAttributedString:secondStringAttr];
    }
    
    return attribute;
}


+ (CGSize)CF_targetString:(NSString *)string sizeWithFont:(UIFont *)font containerSize:(CGSize)containerSize {
    
    return [string boundingRectWithSize:containerSize options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName:font} context:nil].size;
}

+ (BOOL)CF_isEmptyString:(NSString *)string {
    
    BOOL isEmpty = YES;
    if (string && [string isKindOfClass:[NSString class]]) {
        string = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (string.length>0) {
            isEmpty = NO;
        }
    }
    return isEmpty;
}

+ (NSString *)CF_extractNumberFromString:(NSString *)sourceString {
    
    NSCharacterSet* tmpSet = [[NSCharacterSet characterSetWithCharactersInString:@"0123456789"]invertedSet];
    
    NSString *filtered = [[sourceString componentsSeparatedByCharactersInSet:tmpSet]componentsJoinedByString:@""];
    
    return filtered;
    
}

+ (NSString *)CF_extractNumberAndDotFromString:(NSString *)sourceString {
    
    NSCharacterSet* tmpSet = [[NSCharacterSet characterSetWithCharactersInString:@"0123456789."]invertedSet];
    
    NSString *filtered = [[sourceString componentsSeparatedByCharactersInSet:tmpSet]componentsJoinedByString:@""];
    
    return filtered;
}

+ (NSString *)CF_extractNumberAndEnglishLetterFromString:(NSString *)sourceString {
    
    NSCharacterSet* tmpSet = [[NSCharacterSet characterSetWithCharactersInString:@"0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHILKLMNOPQRSTUVWXYZ"]invertedSet];
    
    NSString *filtered = [[sourceString componentsSeparatedByCharactersInSet:tmpSet]componentsJoinedByString:@""];
    
    return filtered;
}

+ (NSString *)CF_extractEnglishLetterFromString:(NSString *)sourceString {
    
    NSCharacterSet* tmpSet = [[NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyzABCDEFGHILKLMNOPQRSTUVWXYZ"]invertedSet];
    
    NSString *filtered = [[sourceString componentsSeparatedByCharactersInSet:tmpSet]componentsJoinedByString:@""];
    
    return filtered;
    
}

+ (void)CF_callWithPhoneNumber:(NSString *)phoneNumber {
    
    NSString *str2 = [[UIDevice currentDevice] systemVersion];
    if ([str2 compare:@"10.0" options:NSNumericSearch] == NSOrderedDescending ||
        [str2 compare:@"10.0" options:NSNumericSearch] == NSOrderedSame) {
        
        NSString *telStr = @"tel";
        NSString *phone = [NSString stringWithFormat:@"%@://%@", telStr, phoneNumber];
        //无延迟，有弹窗【奇怪:iPhone5S 10.2.1无弹窗，iPhone6S 10.2.1有弹窗 iPhone6P 10.1.1 无弹窗】
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:phone]
                                           options:@{}
                                 completionHandler:nil];
    } else {
        //无延迟，有弹窗
        NSString *telStr = [@[@"t",@"e",@"l",@"p",@"r",@"o",@"m",@"p",@"t"] componentsJoinedByString:@""];
        NSString *phone = [NSString stringWithFormat:@"%@://%@", telStr, phoneNumber];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:phone]];
    }
}

+ (NSString *)CF_formatAmount:(NSString *)amount {
    
    NSString *text = [CFTool CF_extractNumberAndDotFromString:amount];
    if ([text hasPrefix:@"."]) {//不能.开头
        text = [text substringFromIndex:1];
    }
    if ([text hasPrefix:@"0"]) {//0开头
        if (text.length >= 2) {
            NSString *secondChar = [text substringWithRange:NSMakeRange(1, 1)];
            if (![secondChar isEqualToString:@"."]) {//0开头，第二个字符不是小数点，则去掉0
                text = [text substringFromIndex:1];
            }
        }
    }
    
    NSArray *components = [text componentsSeparatedByString:@"."];
    if (components.count > 2) {//只能有一个小数点
        text = [NSString stringWithFormat:@"%@.%@", components[0], components[1]];
    } else if (components.count == 2) {//有一个小数点时，后面保留两位小数
        NSString *lastComponent = components[1];
        if (lastComponent.length > 2) {
            lastComponent = [lastComponent substringWithRange:NSMakeRange(0, 2)];
        }
        text = [NSString stringWithFormat:@"%@.%@", components[0], lastComponent];
    }
    
    return text;
}

+ (time_t)CF_Uptime {
    
    struct timeval boottime;
    int mib[2] = {CTL_KERN, KERN_BOOTTIME};
    size_t size = sizeof(boottime);
    time_t now;
    time_t uptime = -1;
    (void)time(&now);
    
    if (sysctl(mib, 2, &boottime, &size, NULL, 0) != -1 && boottime.tv_sec != 0)
    {
        uptime = now - boottime.tv_sec;
    }
    return uptime*1000;
}

+ (NSString *)uuid {
    
    //NSString *uuid = [SAMKeychain passwordForService:kUUID account:kUUIDValue];
    
    NSString *uuid = nil;
    
    if (uuid == nil || [uuid length] == 0) {
        uuid = [CFTool generateUUID];
        //[SAMKeychain setPassword:uuid forService:kUUID account:kUUIDValue];
    }
    
    return uuid;
}

+ (NSString *)generateUUID {
    
    CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
    CFStringRef cfstring = CFUUIDCreateString(kCFAllocatorDefault, uuid);
    const char *cStr = CFStringGetCStringPtr(cfstring,CFStringGetFastestEncoding(cfstring));
    unsigned char result[16];
    CC_MD5( cStr, (CC_LONG)strlen(cStr), result );
    CFRelease(uuid);
    CFRelease(cfstring);
    
    return [NSString stringWithFormat:
            @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%08lx",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15],
            (unsigned long)(arc4random() % NSUIntegerMax)];
}


+ (void)playFeedback {
    
    if (NSClassFromString(@"UIImpactFeedbackGenerator")) {
        UIImpactFeedbackGenerator *feedbackGenerator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium];
        [feedbackGenerator prepare];
        [feedbackGenerator impactOccurred];
    }
}

+ (NSString *)retrieveIDFA {
    
    NSString *advertisingIdentifierSelStr = [NSString stringWithFormat:@"%@%@%@", @"adverti", @"singIde", @"ntifier"];
    NSString *UUIDStringSelStr = [NSString stringWithFormat:@"%@%@%@", @"UU", @"IDStr", @"ing"];
    
    SEL advertisingIdentifierSel = sel_registerName([advertisingIdentifierSelStr UTF8String]);
    SEL UUIDStringSel = sel_registerName([UUIDStringSelStr UTF8String]);
    
    ASIdentifierManager *manager = [ASIdentifierManager sharedManager];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    if([manager respondsToSelector:advertisingIdentifierSel]) {
        id UUID = [manager performSelector:advertisingIdentifierSel];
        if([UUID respondsToSelector:UUIDStringSel]) {
            return [UUID performSelector:UUIDStringSel];
        }
    }
#pragma clang diagnostic pop
    
    return @"";
}


+ (BOOL)isiPhone5SAndLater {
    
    struct utsname systemInfo;
    uname(&systemInfo);
    
    BOOL isiPhone5SAndLater = NO;
    NSString *machineName = [NSString stringWithCString:systemInfo.machine
                                               encoding:NSUTF8StringEncoding];
    NSString *machineNameNew = [machineName componentsSeparatedByString:@","][0];
    if ([machineNameNew hasPrefix:@"iPhone"] && machineNameNew.length > @"iPhone".length) {
        NSString *digit = [machineNameNew substringFromIndex:@"iPhone".length];
        if (digit.intValue >= 6) {
            isiPhone5SAndLater = YES;
        }
        
        NSLog(@"machineName: %@, digit: %@, isiPhone5SAndLater: %@", machineName, digit, isiPhone5SAndLater?@"YES":@"NO");
    }
    
    return isiPhone5SAndLater;
}


@end
