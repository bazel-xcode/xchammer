//
//  CompilationDatabase.m
//  Pinterest
//
//  Created by Jerry Marino on 5/18/17.
//  Copyright © 2017 Pinterest. All rights reserved.
//

#import "CompilationDatabase.h"
#import "XCDependencyGraph.h"

// Shell lexer
// The data type is a string, but we need a correctly lexed version of that
// string as a shell would do it.
static NSArray *shlex(NSString *s) {
    NSMutableArray *result = [NSMutableArray array];
    NSMutableString *accumulator = [NSMutableString string];
    char quote = '\0';
    bool escape = false;
    for (int i = 0; i < s.length; i++) {
        unichar c;
        [s getCharacters:&c range:NSMakeRange(i, 1)];
        if (escape) {
            // start escape
            escape = false;
            NSString *str = [NSString stringWithCharacters:&c length:1];
            [accumulator appendString:str];
        } else if (c == '\\') {
            escape = true;
        } else if ((quote == '\0' && c == '\'') ||
                   (quote == '\0' && c == '\"')) {
            // start quoted sequence
            quote = c;
        } else if (
                   (quote == '\'' && c == '\'') ||
                   (quote == '"'  && c == '"')
                   ) {
            // end quoted sequence
            quote = '\0';
        } else if ((!isspace(c) || quote != '\0')) {
            // accumulate character (which is either non-whitespace or quoted)
            NSString *str = [NSString stringWithCharacters:&c length:1];
            [accumulator appendString:str];
        } else {
            // evict accumulator
            if (accumulator.length > 0) {
                [result addObject:accumulator];
                accumulator = [NSMutableString string];
            }
        }
    }
    
    if (accumulator.length > 0) {
        [result addObject:accumulator];
        accumulator = [NSMutableString string];
    }
    return result;
}




@implementation CompilationDatabaseEntry


- (instancetype)initWithFile:(NSString *)file command:(NSArray *)command directory:(NSString *)directory
{
    if (self = [super init]) {
        _file = file;
        _command = command;
        _directory = directory;
    }
    return self;
}

@end

@implementation XCCompilationDatabase
{
    XCDependencyGraph *_graph;
}

- (instancetype)initWithBuildDirectory:(NSString *)buildDirectory
{
    if (self = [super init]) {
        NSError *e;
        PBXTargetBuildContext *ctx = [NSClassFromString(@"PBXTargetBuildContext") new];
        XCDependencyGraph *graph = [NSClassFromString(@"XCDependencyGraph") readFromBuildDirectory:buildDirectory withTargetBuildContext:ctx error:&e];
        assert(graph);
        assert(e == nil && "Can't create graph");
       
        _graph = graph;

        NSDictionary <NSString *, XCDependencyCommandInvocationRecord *> *records = [graph valueForKey:@"_commandInvocRecordsByIdent"];
        NSMutableArray <CompilationDatabaseEntry *>*buildCommand = [NSMutableArray array];
        // This for loop creates compilation DB entries from XCDependencyCommandInvocationRecord's
        for (NSString *key in records) {
            XCDependencyCommandInvocationRecord *record = records[key];
            if ([record.identifier hasPrefix:@"CompileC"]) {
                NSArray *CLIArgs = record.commandLineArguments;
                NSArray *lexedTitle = shlex(key);
                NSString *sourceFile = lexedTitle[2];
                CompilationDatabaseEntry *entry = [[CompilationDatabaseEntry alloc] initWithFile:sourceFile command:CLIArgs directory:@""];
                [buildCommand addObject:entry];
            }
        }
       
        _entries = buildCommand;
    }
    return self;
}

- (void)dump
{
    [_graph printNodes];
}

@end


@implementation JSONCompilationDatabase

- (instancetype)initWithJSON:(NSArray *)JSONArray
{
    if (self = [super init]) {
        NSMutableArray *entries = [NSMutableArray array];
        for (NSDictionary *entryJSON in JSONArray) {
            NSArray *CLIArgs = shlex(entryJSON[@"command"]);
            CompilationDatabaseEntry *entry = [[CompilationDatabaseEntry alloc] initWithFile:entryJSON[@"file"] command:CLIArgs directory:@""];
            [entries addObject:entry];
        }
        _entries = entries;
    }
    return self;
}

- (instancetype)init
{
    if (self = [super init]) {
        _entries = [NSArray array];
    }
    return self;
}


@end

id < CompilationDatabase> mergeCompDB(id<CompilationDatabase> a, id<CompilationDatabase> b) {
    NSArray *allEntries = [a.entries arrayByAddingObjectsFromArray:b.entries];
    JSONCompilationDatabase *out = [JSONCompilationDatabase new];
    [out setValue:allEntries forKey:@"_entries"];
    return out;
}

