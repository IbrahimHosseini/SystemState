//
//  Header.h
//  
//
//  Created by Ibrahim on 3/12/24.
//

#import <Foundation/Foundation.h>

@interface LLDB:NSObject
-(instancetype)init:(NSString *) path;

-(NSArray *)keys:(NSString *)key;

-(bool)insert:(NSString *)key value:(NSString *)value;

-(NSString *)findOne:(NSString *)key;
-(NSString *)findLast:(NSString *)prefix;
-(NSArray *)findMany:(NSString *)prefix;

-(bool)deleteOne:(NSString *)key;
-(bool)deleteMany:(NSArray*)keys;

-(void)close;

@end
