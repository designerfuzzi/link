//
//  QCAbletonLinkObject.m
//  Link
//
//  Created by Frank Hofmann on 25.11.18.
//

#import "QCAbletonLinkObject.h"

@implementation QCAbletonLinkObject {
    QCAbletonLink::State state;
    double beats;
    double phase;
    double tempo;
    std::size_t numPeers;
    double _quantum;
    bool startStopSyncOn;
    std::chrono::microseconds linkTime;
}
@synthesize transport = _transport;
#pragma mark guaranteed singleton
/* When ARC is not enabled, use the dispatch_retain and dispatch_release functions (or Objective-C semantics) to retain and release your dispatch objects. You cannot use the Core Foundation retain/release functions. If you need to use retain/release semantics in an ARC-enabled app with a later deployment target (for maintaining compatibility with existing code), you can disable Objective-C-based dispatch objects by adding -DOS_OBJECT_USE_OBJC=0 to your compiler flags.
 */

#if ABLLinkQuartzSingleton == 1
#if !__i386__
#else
static QCAbletonLinkObject * _abletonLinkObjectSharedInstance = nil;
#endif
+(instancetype)sharedInstance {
    //#if __MAC_OS_X_VERSION_MAX_ALLOWED > 1060
#if !__i386__
    __strong static id _abletonLinkObjectSharedInstance = nil;
    static dispatch_once_t onlyOnce;
    dispatch_once(&onlyOnce, ^{
        _abletonLinkObjectSharedInstance = [[self _alloc] _init];
    });
#else
    //definition moved to global scope...
    //static QCAbletonLinkObject * _abletonLinkObjectSharedInstance = nil;
    @synchronized(self) {
        if(_abletonLinkObjectSharedInstance == nil) {
            _abletonLinkObjectSharedInstance = [[self _alloc] _init];
        }
    }
#endif
    return _abletonLinkObjectSharedInstance;
}

//-(methodtype)methodname OBJC_ARC_UNAVAILABLE;

+(id)allocWithZone:(NSZone *)zone {
#if ! __has_feature(objc_arc)
    return [[self sharedInstance] retain];
#else
    return [self sharedInstance];
#endif
}

#if ! __has_feature(objc_arc)
+(id)copyWithZone:(NSZone *)zone {
    return self;
}
-(id)retain {
    return self;
}
-(NSUInteger)retainCount {
    return UINT_MAX;
}
-(oneway void)release {
    //never release
}
-(id)autorelease {
    return self;
}
#endif

+(id)alloc {
    //NSLog(@"alloc QCAbletonLinkObject");
    //uncomment following to force sharedInstances even if normal allocated
#if ! __has_feature(objc_arc)
    return [[self sharedInstance] retain];
#else
    return [self sharedInstance];
#endif
}
+(id)_alloc {
    //NSLog(@"_alloc QCAbletonLinkObject");
    return [super allocWithZone:NULL];
}

-(id)_init{
    //NSLog(@"_init QCAbletonLinkObject");
#if __i386__
    NSLog(@"QuartzComposer Link Plug-In running in 32bit mode.");
#endif
    
#if __LP64__
    NSLog(@"QuartzComposer Link Plug-In running in 64bit mode.");
#endif
    return [super init];
}

-(void)dealloc {
    //!-fobj-arc means has NoAutoReferenceCounting
#if ! __has_feature(objc_arc)
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"QCAbletonLinkOnStartStopChanged" object:nil];
    [super dealloc];
#endif
}

#endif //endif useABLLinkQuartzSingleton

-(id)init {
    //NSLog(@"init QCAbletonLinkObject");
    //real Init procedure..
    _quantum = 4.0;
    
    state.link.enable(true);
    
    state.running = true;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(syncChanged:) name:@"QCAbletonLinkOnStartStopChanged" object:nil];
    
    state.link.setStartStopCallback(onStartStopChanged);
    
    return self;
}

-(void)syncChanged:(NSNotification*)notiz {
    bool run = (bool)[notiz.userInfo[@"QCAbletonLinkStartStopCall"] boolValue];
    //NSLog(@"sync notification:%d",run);
    [self setTransport:run];
}
void onStartStopChanged(bool on) {
    //NSLog(@"sync onStartStopChanged = %d",on);
    [[NSNotificationCenter defaultCenter] postNotificationName:@"QCAbletonLinkOnStartStopChanged"
                                                        object:nil
                                                      userInfo:@{ @"QCAbletonLinkStartStopCall": @(on)}];
}


-(ABLLinkSessionStateRef)sessionState {
    //return state.link.captureAudioSessionState();
    return state.link.captureAppSessionState();
}
-(bool)isTransport {
    return _transport;
}
-(void)setTransport:(bool)on {
    //NSLog(@"sync setSessionIsPlaying = %d",on);
    _transport = on;
}
-(bool)sessionIsPlaying {
    return self.sessionState.isPlaying();
}

-(void)startMetronome {
    state.audioPlatform.mEngine.startPlaying();
}
-(void)stopMetronome {
    state.audioPlatform.mEngine.stopPlaying();
}
-(bool)metronomeIsPlaying {
    return state.audioPlatform.mEngine.isPlaying();
}
-(double)quantum {
    //return state.audioPlatform.mEngine.quantum();
    return _quantum;
}
-(void)setQuantum:(double)quantum {
    state.audioPlatform.mEngine.setQuantum(quantum);
    _quantum = quantum;
}
-(double)tempo {
    tempo = self.sessionState.tempo();
    return roundf( tempo * 100) / 100;
}
-(NSUInteger)numPeers {
    numPeers = state.link.numPeers();
    return (NSUInteger)numPeers;
}
-(double)beats {
    beats = self.sessionState.beatAtTime(state.link.clock().micros(), _quantum);
    return beats;
}
-(double)phase {
    phase = self.sessionState.phaseAtTime(state.link.clock().micros(), _quantum);
    return phase;
}
-(double)quantumPhase {
    return roundf( (phase / _quantum) * 1000000) / 1000000;
}

-(void)requestTempo:(double)bpm {
    //state.audioPlatform.mEngine.setTempo(bpm);
    ABLLinkSessionStateRef session = [self sessionState];
    session.setTempo(bpm, state.link.clock().micros());
    state.link.commitAppSessionState(session);
}
-(void)requestBeat:(double)beat {
    ABLLinkSessionStateRef session = [self sessionState];
    session.requestBeatAtTime(ceil(self.beats), session.timeAtBeat(ceil(self.beats), _quantum), _quantum);
    state.link.commitAppSessionState(session);
}
-(void)setStartStopSync:(bool)on {
    //state.audioPlatform.mEngine.setStartStopSyncEnabled(on);
    state.link.enableStartStopSync(on);
}
-(bool)isStartStopSyncEnabled {
    //return state.audioPlatform.mEngine.isStartStopSyncEnabled();
    return state.link.isStartStopSyncEnabled();
}

-(bool)isEnabled {
    return state.link.isEnabled();
}
-(void)setEnabled:(bool)bEnable {
    state.link.enable(bEnable);
    state.running = bEnable;
}

-(bool)running {
    return state.running;
}
-(void)stopRunning {
    state.running = false;
}
-(void)startRunning {
    state.running = true;
}
-(void)setRunning:(bool)on {
    state.running = on;
}

-(void)closeLinkPeer {
    state.audioPlatform.mEngine.stopPlaying();
    [self setEnabled:false];
    [self stopRunning];
}

//FIXME: getting ticks similar to miditicks from timeline
-(uint64_t)ticks {
    //ableton::platforms::darwin::Clock::Ticks();
    return 0;
}
@end
