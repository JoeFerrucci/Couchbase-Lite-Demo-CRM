//
//  CBLSocialSync.m
//  TodoLite7
//
//  Created by Chris Anderson on 11/16/13.
//  Copyright (c) 2013 Chris Anderson. All rights reserved.
//

#import "CBLSyncManager.h"
#import <FacebookSDK/FacebookSDK.h>


@interface CBLSyncManager()<FBLoginViewDelegate>  {
    CBLReplication *pull;
    CBLReplication *push;
    NSArray *beforeSyncBlocks;
    NSArray *onSyncStartedBlocks;
}
@end

@implementation CBLSyncManager

- (instancetype) initSyncForDatabase:(CBLDatabase*)database
                             withURL:(NSURL*)remoteURL {
    NSString* userID = [[NSUserDefaults standardUserDefaults] objectForKey: kCBLPrefKeyUserID];
    return [self initSyncForDatabase:database withURL:remoteURL asUser:userID];
}

- (instancetype) initSyncForDatabase:(CBLDatabase*)database
                             withURL:(NSURL*)remoteURL
                              asUser:(NSString*)userID {
    self = [super init];
    if (self) {
        _database = database;
        _userID = userID;
        _remoteURL = remoteURL;
        beforeSyncBlocks = @[];
        onSyncStartedBlocks = @[];
    }
    return self;
}

#pragma mark - Public Instance API

- (void) start {
    if (!_userID) {
        [self setupNewUser: ^(){
            [self launchSync];
        }];
    } else {
        [self launchSync];
    }
}

//- (void)useFacebookAppID: (NSString *)myAppID {
//    _authenticator = [[CBLFacebookAuthenticator alloc]initWithAppID: myAppID];
//}


- (void)beforeFirstSync: (void (^)(NSString *userID, NSDictionary *userData, NSError **outError))block {
    beforeSyncBlocks = [beforeSyncBlocks arrayByAddingObject:block];
}

- (void)onSyncConnected: (void (^)())block {
    onSyncStartedBlocks = [onSyncStartedBlocks arrayByAddingObject:block];
}

- (void)setAuthenticator:(NSObject<CBLSyncAuthenticator> *)authenticator {
    _authenticator = authenticator;
    _authenticator.syncManager = self;
}


#pragma mark - Callbacks

- (NSError*) runBeforeSyncStartWithUserID: (NSString *)userID andUserData: (NSDictionary *)userData {
    void (^beforeSyncBlock)(NSString *userID, NSDictionary *userData, NSError **outError);
    NSError *error;
    for (beforeSyncBlock in beforeSyncBlocks) {
        if (error) return error;
        beforeSyncBlock(userID, userData, &error);
    }
    return error;
}

#pragma mark - Sync related

- (void)logout{
    if (!self.userID) {
        NSLog(@"here is should be self.syncManager.userID");
    }else{
        [self.authenticator logoutUser:self.userID];
        [[NSUserDefaults standardUserDefaults] setObject:nil forKey:kCBLPrefKeyUserID];
        _userID = nil;
        [[NSUserDefaults standardUserDefaults] synchronize];
        
    }
}

- (void) launchSync {
    NSLog(@"launch Sync");
    
    [self defineSync];
    
    
    [self startSync];
    
    //    void (^onSyncStartedBlock)();
    //    for (onSyncStartedBlock in onSyncStartedBlocks) {
    //        onSyncStartedBlock();
    //    }
    
}

- (void)defineSync
{
    pull = [_database replicationFromURL:_remoteURL];
    pull.continuous = YES;
    //    pull.persistent = YES;
    
    push = [_database replicationToURL:_remoteURL];
    push.continuous = YES;
    //    push.persistent = YES;
    
    [self listenForReplicationEvents: push];
    [self listenForReplicationEvents: pull];
    
    [_authenticator registerCredentialsWithReplications: @[pull, push]];
}

- (void) listenForReplicationEvents: (CBLReplication*) repl {
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(replicationProgress:)
                                                 name: kCBLReplicationChangeNotification
                                               object: repl];
}


- (void) replicationProgress: (NSNotificationCenter*)n {
    bool active = false;
    unsigned completed = 0, total = 0;
    CBLReplicationStatus status = kCBLReplicationStopped;
    NSError* error = nil;
    for (CBLReplication* repl in @[pull, push]) {
        NSLog(@"current status: %i for repl: %@", repl.status, repl);
        status = MAX(status, repl.status);
        if (!error)
            error = repl.lastError;
        if (repl.status == kCBLReplicationActive) {
            active = true;
            completed += repl.completedChangesCount;
            total += repl.changesCount;
        }
    }
    
    if (error != _error && error.code == 401) {
        // Auth needed (or auth is incorrect), ask the _authenticator to get new credentials.
        [_authenticator getCredentials:^(NSString *newUserID, NSDictionary *userData) {
            //            todo this should call our onSyncAuthError callback
            NSAssert2([newUserID isEqualToString:_userID], @"can't change userID from %@ to %@, need to reinstall", _userID,  newUserID);
        }];
    }
    [self updateActuvityForStatus:status];
    //TODO: need to be removed after 'status' will be fixed.
    if(total == completed){
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    }else{
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    }
    if (active != _active || completed != _completed || total != _total || status != _status
        || error != _error) {
        _active = active;
        _completed = completed;
        _total = total;
        _progress = (completed / (float)MAX(total, 1u));
        _status = status;
        _error = error;
        NSLog(@"SYNCMGR: active=%d; status=%d; %u/%u; %@",
              active, status, completed, total, error.localizedDescription); //FIX: temporary logging
        //        [[NSNotificationCenter defaultCenter]
        //         postNotificationName: SyncManagerStateChangedNotification
        //         object: self];
        
    }
}

- (void)startSync {
    //    todo listen for sync errors
    NSLog(@"startSync");
    [pull start];
    [push start];
}

- (void)updateActuvityForStatus:(CBLReplicationStatus)st{
    NSLog(@"current status: %i", st);
    if(st == kCBLReplicationStopped || st == kCBLReplicationIdle){
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    }else{
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    }
    
}

#pragma mark - User ID related

- (void) setupNewUser:(void (^)())complete {
    if (_userID) return;
    [_authenticator getCredentials: ^(NSString *userID, NSDictionary *userData){
        if (_userID) return;
        // Give the app a chance to tag documents with userID before sync starts
        NSError *error = [self runBeforeSyncStartWithUserID: userID andUserData: userData];
        if (error) {
            NSLog(@"error preparing for sync %@", error);
        } else {
            _userID = userID;
            complete();
        }
    }];
}


@end

@implementation CBLFacebookAuthenticator

@synthesize syncManager=_syncManager;

- (instancetype) initWithAppID:(NSString *)appID {
    self = [super init];
    if (self) {
        _facebookAppID = appID;
    }
    return self;
}

-(void) getCredentials: (void (^)(NSString *userID, NSDictionary *userData))block {
    
    [FBSession openActiveSessionWithReadPermissions:@[@"basic_info"]
                                       allowLoginUI:YES
                                  completionHandler:
     ^(FBSession *session, FBSessionState state, NSError *error) {
         FBRequest* request =[FBRequest requestForMe];
         [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *me_error) {
             if(!error){
                 NSDictionary* userData = result;
                 NSString *userID = userData[@"email"];
                 if(!session.accessTokenData){
                     NSLog(@"ERROR: here is should be token");
                     block(nil, nil);
                 }else{
                     if(!userID)
                         userID = [userData[@"name"] stringByReplacingOccurrencesOfString:@" " withString:@""].lowercaseString;
                     // Store the access_token for later.
                     [[NSUserDefaults standardUserDefaults] setObject: session.accessTokenData.accessToken forKey: [self accessTokenKeyForUserID:userID]];
                     block(userID, userData);
                 }
             }else {
                 NSLog(@"error: %@", error);
                 
             }
         }];
     }];
}

-(void) registerCredentialsWithReplications: (NSArray *)repls {
    NSString* userID = _syncManager.userID;
    NSString* accessToken = [[NSUserDefaults standardUserDefaults] objectForKey: [self accessTokenKeyForUserID:userID]];
    if (!userID) return;
    for (CBLReplication * repl in repls) {
        NSLog(@"repl %@", repl);
        [repl setFacebookEmailAddress:userID];
        [repl registerFacebookToken:accessToken forEmailAddress:userID];
    }
}

#pragma mark - Facebook API related

- (void)logoutUser:(NSString*)userID{
    if (!userID) {
        NSLog(@"here is should be self.syncManager.userID");
    }else{
        [FBSession.activeSession closeAndClearTokenInformation];
        [[NSUserDefaults standardUserDefaults] setObject: nil forKey: [self accessTokenKeyForUserID:userID]];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (NSString*) accessTokenKeyForUserID: (NSString *)userID {
    return [@"CBLFBAT-" stringByAppendingString: userID];
}

@end
