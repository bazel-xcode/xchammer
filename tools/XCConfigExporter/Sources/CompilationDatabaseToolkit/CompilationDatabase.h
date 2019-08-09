//
//  CompilationDatabase.h
//  Pinterest
//
//  Created by Jerry Marino on 5/18/17.
//  Copyright © 2017 Pinterest. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CompilationDatabaseEntry : NSObject

@property (nonatomic, readonly) NSArray *command;
@property (nonatomic, readonly) NSString *file;
@property (nonatomic, readonly) NSString *directory;

- (instancetype)initWithFile:(NSString *)file command:(NSArray *)command directory:(NSString *)directory;

@end


@protocol CompilationDatabase <NSObject>

@property (nonatomic, readonly) NSArray <CompilationDatabaseEntry *> *entries;

@end

@interface XCCompilationDatabase : NSObject <CompilationDatabase>

@property (nonatomic, readonly) NSArray <CompilationDatabaseEntry *>*entries;

- (instancetype)initWithBuildDirectory:(NSString *)buildDirectory;

- (void)dump;

@end

id <CompilationDatabase> mergeCompDB(id<CompilationDatabase> a, id<CompilationDatabase> b);

@interface JSONCompilationDatabase : NSObject <CompilationDatabase>

@property (nonatomic, readonly) NSArray <CompilationDatabaseEntry *>*entries;

- (instancetype)initWithJSON:(NSArray *)JSONArray;

@end
