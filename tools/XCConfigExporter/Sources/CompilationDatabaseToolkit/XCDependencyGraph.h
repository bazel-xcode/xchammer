//
//  XCDependencyGraph.h
//  XcodeDepGraph
//
//  Created by Jerry Marino on 5/16/17.
//  Copyright © 2017 SwiftySwiftVim. All rights reserved.
//

@class XCDependencyNode;
@class PBXTargetBuildContext;

@interface XCDependencyGraph : NSObject
{
@public
    PBXTargetBuildContext *_buildContext;
    NSMutableArray *_nodesByNumber;
    // Error parsing type: AB, name: _nodesByNumberLock
    XCDependencyNode *_rootNode;
    XCDependencyNode *_baseNode;
    NSMutableDictionary *_virtualNodesByIdent;
    // Error parsing type: AB, name: _virtualNodesByIdentLock
    NSMutableDictionary *_commandInvocRecordsByIdent;
    // Error parsing type: AB, name: _commandInvocRecordsByIdentLock
    NSSet *_buildActionProducedArtifactNodes;
    NSMutableArray *_commandsByNumber;
    // Error parsing type: AB, name: _commandsByNumberLock
}

+ (id)readFromBuildDirectory:(id)arg1 withTargetBuildContext:(id)arg2 error:(id *)arg3;
+ (id)loadOrCreateInBuildDirectory:(id)arg1 withTargetBuildContext:(id)arg2 withBasePath:(id)arg3;
+ (id)dependencyGraphFilename;
@property(copy) NSSet *buildActionProducedArtifactNodes; // @synthesize buildActionProducedArtifactNodes=_buildActionProducedArtifactNodes;
- (id)description;
- (void)printNodes;
- (BOOL)isValid;
- (void)invalidate;
- (BOOL)_writeToBuildDirectory:(id)arg1 forceWrite:(BOOL)arg2 error:(id *)arg3;
- (BOOL)writeToBuildDirectory:(id)arg1 error:(id *)arg2;
- (BOOL)isOutOfDateFromPersistedRepresentationInBuildDirectory:(id)arg1;
- (BOOL)writeToByteStream:(struct __sFILE *)arg1 error:(id *)arg2;
- (id)initFromByteStream:(struct __sFILE *)arg1 withTargetBuildContext:(id)arg2 error:(id *)arg3;
- (id)lookupCommandInvocationRecordWithIdentifier:(id)arg1;
- (id)createCommandInvocationRecordWithIdentifier:(id)arg1;
//- (void)enumerateCommandsUsingBlock:(CDUnknownBlockType)arg1;
- (unsigned int)highestAssignedCommandNumber;
//- (id)createShadowCommandWithOriginalCommand:(id)arg1 outputFilePath:(id)arg2 subprocessCommandLineGenerationBlock:(CDUnknownBlockType)arg3;
- (id)createCommandWithIdentifier:(id)arg1 macroExpansionScope:(id)arg2;
- (id)createCommandOfClass:(Class)arg1 withIdentifier:(id)arg2 macroExpansionScope:(id)arg3;
//- (void)enumerateNodesUsingBlock:(CDUnknownBlockType)arg1;
- (unsigned int)highestAssignedNodeNumber;
- (id)virtualNodeWithIdentifier:(id)arg1 createIfNeeded:(BOOL)arg2;
- (id)nodeWithPath:(id)arg1 createIfNeeded:(BOOL)arg2;
- (id)nodeWithPath:(id)arg1 relativeToNode:(id)arg2 createIfNeeded:(BOOL)arg3;
- (id)createNodeWithSupernode:(id)arg1 nameCStr:(const char *)arg2 length:(unsigned long long)arg3 isVirtual:(_Bool)arg4;
- (void)prepareForUpdatingDependencyGraph;
- (id)basePath;
- (id)targetBuildContext;
- (id)init;
- (id)initWithBasePath:(id)arg1 targetBuildContext:(id)arg2;

@end

@interface XCDependencyCommandInvocationRecord : NSObject
{
    XCDependencyGraph *_depGraph;
    NSString *_identifier;
    //    CDStruct_7eef4560 _commandSignature;
    NSString *_execDescription;
    NSArray *_commandLineArgs;
    NSArray *_environAssignments;
    XCDependencyNode *_workingDirNode;
    double _startTime;
    double _endTime;
    int _exitStatus;
    NSString *_builderIdent;
    id _activityLog; // 0
    //    IDEActivityLogSection *_activityLog;
    NSArray *_inputNodeStates;
    NSArray *_outputNodes;
}

- (id)description;
- (id)stringRepresentation;
//- (id)initFromStringRepresentation:(id)arg1 inDependencyGraph:(id)arg2 errorHandler:(CDUnknownBlockType)arg3;
- (BOOL)isValid;
- (void)invalidate;
- (id)dependencyGraph;
- (void)setOutputNodes:(id)arg1;
- (id)outputNodes;
- (void)setInputNodeStates:(id)arg1;
- (id)inputNodeStates;
- (void)setActivityLog:(id)arg1;
- (id)activityLog;
- (void)setBuilderIdentifier:(id)arg1;
- (id)builderIdentifier;
- (void)setExitStatus:(int)arg1;
- (int)exitStatus;
- (void)setEndTime:(double)arg1;
- (double)endTime;
- (void)setStartTime:(double)arg1;
- (double)startTime;
- (void)setWorkingDirectoryNode:(id)arg1;
- (id)workingDirectoryNode;
- (void)setEnvironmentAssignments:(id)arg1;
- (id)environmentAssignments;
- (void)setCommandLineArguments:(id)arg1;
- (id)commandLineArguments;
- (void)setExecutionDescription:(id)arg1;
- (id)executionDescription;
- (id)identifier;
- (id)init;
- (id)initWithIdentifier:(id)arg1 inDependencyGraph:(id)arg2;
- (id)initWithIdentifier:(id)arg1 executionDescription:(id)arg2 commandLineArguments:(id)arg3 environmentAssignments:(id)arg4 workingDirectoryNode:(id)arg5 startTime:(double)arg6 endTime:(double)arg7 exitStatus:(int)arg8 builderIdentifier:(id)arg9 activityLog:(id)arg10 inputNodeStates:(id)arg11 outputNodes:(id)arg12 inDependencyGraph:(id)arg13;

@end

@class DVTDocumentLocation, IDEActivityLogSectionRecorder, IDETypeIdentifier, NSArray, NSMutableArray, NSMutableString, NSString, NSURL;

@interface IDEActivityLogSection : NSObject <NSCopying>
{
    IDEActivityLogSectionRecorder *_recorder;
    IDETypeIdentifier *_domainType;
    NSString *_title;
    double _timeStartedRecording;
    double _timeStoppedRecording;
    NSMutableArray *_subsections;
    NSMutableString *_text;
    NSMutableArray *_messages;
    id _representedObject;
    NSString *_subtitle;
    DVTDocumentLocation *_location;
    NSString *_signature;
    NSString *_commandDetailDesc;
    unsigned short _totalTestFailureCount;
    unsigned short _totalErrorCount;
    unsigned short _totalWarningCount;
    unsigned short _totalAnalyzerWarningCount;
    unsigned short _totalAnalyzerResultCount;
    unsigned short _sectionType;
    unsigned short _sectionAuthority;
    unsigned short _resultCode;
    BOOL _wasCancelled;
    BOOL _isQuiet;
    BOOL _wasFetchedFromCache;
    BOOL _hasAddedIssueMessage;
    NSString *_uniqueIdentifier;
    NSString *_localizedResultString;
    int _lock;
}

+ (id)sectionWithContentsOfFile:(id)arg1 error:(id *)arg2;
+ (id)sectionByDeserializingData:(id)arg1 error:(id *)arg2;
+ (unsigned long long)serializationFormatVersion;
+ (id)UUIDWithURL:(id)arg1;
+ (id)URLWithUUID:(id)arg1;
+ (id)defaultMainLogDomainType;
+ (id)defaultLogSectionDomainType;
+ (Class)logRecorderClass;
+ (void)initialize;
@property(readonly) NSString *uniqueIdentifier; // @synthesize uniqueIdentifier=_uniqueIdentifier;
@property(copy) NSString *localizedResultString; // @synthesize localizedResultString=_localizedResultString;
@property BOOL hasAddedIssueMessage; // @synthesize hasAddedIssueMessage=_hasAddedIssueMessage;
@property BOOL wasFetchedFromCache; // @synthesize wasFetchedFromCache=_wasFetchedFromCache;
@property(readonly) IDETypeIdentifier *domainType; // @synthesize domainType=_domainType;
@property unsigned short sectionAuthority; // @synthesize sectionAuthority=_sectionAuthority;
- (id)indexPathForMessageOrSection:(id)arg1;
- (id)indexPathForMessageOrSection:(id)arg1 messageOrSectionEqualityTest:(id)arg2;
- (id)messageOrSectionAtIndexPath:(id)arg1;
- (BOOL)writeToFile:(id)arg1 error:(id *)arg2;
- (id)serializedData;
- (void)dvt_writeToSerializer:(id)arg1;
- (id)dvt_initFromDeserializer:(id)arg1;
- (void)removeObserver:(id)arg1;
- (id)addObserverUsingBlock:(id)arg1;
- (id)enumerateMessagesUsingBlock:(id)arg1;
- (id)enumerateSubsectionsRecursivelyUsingPreorderBlock:(id)arg1;
- (void)_enumerateSubsectionsRecursivelyUsingPreorderBlock:(id)arg1 returningFilteredSections:(void)arg2;
@property(readonly) NSURL *logSectionURL;
- (id)emittedOutputText;
- (void)logRecorder:(id)arg1 setCommandDetailDescription:(id)arg2;
@property(readonly) NSString *commandDetailDescription;
@property(readonly) DVTDocumentLocation *location;
- (void)logRecorder:(id)arg1 setWasFetchedFromCache:(BOOL)arg2;
- (void)logRecorder:(id)arg1 setIsQuiet:(BOOL)arg2;
@property(readonly) BOOL isQuiet;
- (void)logRecorder:(id)arg1 adjustMessageCountsWithTestFailureDelta:(long long)arg2 errorCountDelta:(long long)arg3 warningCountDelta:(long long)arg4 analyzerWarningDelta:(long long)arg5 analyzerResultDelta:(long long)arg6;
@property(readonly) unsigned long long totalNumberOfAnalyzerResults;
@property(readonly) unsigned long long totalNumberOfAnalyzerWarnings;
@property(readonly) unsigned long long totalNumberOfWarnings;
@property(readonly) unsigned long long totalNumberOfErrors;
@property(readonly) unsigned long long totalNumberOfTestFailures;
- (id)description;
- (void)logRecorder:(id)arg1 didStopRecordingWithInfo:(id)arg2;
- (void)checkMessageCounts;
@property(readonly) IDEActivityLogSectionRecorder *recorder;
@property(readonly) BOOL isRecording;
- (void)logRecorder:(id)arg1 setWasCancelled:(BOOL)arg2;
@property(readonly) long long resultCode;
@property(readonly) BOOL wasCancelled;
- (void)logRecorder:(id)arg1 addMessage:(id)arg2;
@property(readonly) NSArray *messages;
- (void)logRecorder:(id)arg1 appendText:(id)arg2;
- (void)setAdditionalDescription:(id)arg1;
@property(readonly) NSString *subtitle;
@property(readonly) NSString *text;
- (void)logRecorder:(id)arg1 addSubsection:(id)arg2;
@property(readonly) NSArray *subsections;
@property(readonly) double timeStoppedRecording;
@property(readonly) double timeStartedRecording;
@property(copy) NSString *signature;
@property(readonly) NSString *title;
@property(readonly) id representedObject;
- (void)setRepresentedObject:(id)arg1;
- (id)copyWithZone:(struct _NSZone *)arg1;
- (void)dealloc;
@property(readonly) unsigned long long sectionType;
- (id)initWithTitle:(id)arg1;
- (id)init;
- (id)initWithSectionType:(unsigned long long)arg1 domainType:(id)arg2 title:(id)arg3;
- (id)initCommandInvocationWithDomainType:(id)arg1 title:(id)arg2 detailDescription:(id)arg3 filePath:(id)arg4;
- (id)initCommandInvocationWithDomainType:(id)arg1 title:(id)arg2 detailDescription:(id)arg3 location:(id)arg4;
- (id)initMajorGroupWithDomainType:(id)arg1 title:(id)arg2 representedObject:(id)arg3 subtitle:(id)arg4;
- (id)initMainLogWithDomainType:(id)arg1 title:(id)arg2;
- (id)initWithSectionType:(unsigned long long)arg1 domainType:(id)arg2 title:(id)arg3 location:(id)arg4;

@end
