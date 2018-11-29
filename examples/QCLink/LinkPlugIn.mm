//
//  LinkPlugIn.m
//  Ableton Link
//
//  Created by Frank Hofmann on 23.11.18.
//  Copyright © 2018 Frank Hofmann. released under GPL2.
//
//  float val = 37.777779;
//  float rounded_down = floorf(val * 100) / 100;   // Result: 37.77
//  float nearest = roundf(val * 100) / 100;  // Result: 37.78
//  float rounded_up = ceilf(val * 100) / 100;      // Result: 37.78


// It's highly recommended to use CGL macros instead of changing the current context for plug-ins that perform OpenGL rendering


#import "QCAbletonLinkObject.h"

//#import <OpenGL/CGLMacro.h>
#import "LinkPlugIn.h"

#define    kQCPlugIn_Name               @"Ableton Link"
#define    kQCPlugIn_Description        @"Ableton Link based on Link 3.0.2\n\n\nINPUTS\n\n\nEnabled = enables and disables the peer in the session.\n\nPlay = plays the phase and beats depending on quantum in the requested or received session tempo. You can turn it off, QuantumPhase will still play with the last set Quantum.\n\nQuanta = amount of steps in one BAR (Quanta).\n\nRequestTempo = here you can force the whole session to take your tempo. Be careful, you really influence all Peers in the session. And you should avoid (you should NOT) force permanent tempo requests, you may break the whole session and make it jittery. So just DO NOT feed it with time related data like 'time' or similar constantly changing values.\n\nSync to Start/Stop = specifies that you would want to start playing together with other peers when they are synced also. If turned off it doesnt force other synced peers in the session to start also when you start.\n\n\nOUTPUTS\n\n\nisPlaying = this Peer is momentary playing in tempo and local quantum settings.\n\nBPM = well, the beats per minute, you may want to format the number with Number Formatter type='none' and format '0.00'. That way you see the human readable bpm and not 119.999999999.\n\nPhase = number expressing where the local playhead is in the quantum span, expressed in floating point quantum steps. Phase may become negative when you receive session data before quantum hits cycle boundarys and didnt start in sync.\n\nBeats = floating number of beats since the session is started.\n\nPeers = amount of Apps running in the same Link session in your network. (keep in mind, at the moment each dropped plugin is also one independed peer watching the network)\n\nQuantumPhase = floating number between [0.0..1.0] telling where your playhead is in the quantum span. So if you would have set 4 quantum steps (which is also preset standard), step 2 of the quantumphase would be expressed as 0.5.\n\nms/Beats = Milliseconds for one Beat at the momentary tempo"
#define    kQCPlugIn_Copyright          @"Implementation: Frank Oszillo (berlin, germany),\nreleased under GPL2"
#define    kQCPlugIn_Category           @"Network"
#define kKeyPath1 @"Allow999"
//#define kKeyPath2 @"Ticks"


@interface LinkPlugIn ()

@end

@implementation LinkPlugIn {
    QCAbletonLinkObject *_abletonLink;
    double _quantum;
    bool _startStopSyncOn;
    BOOL _playMetronome;
    double _maximumBpm;
    double _phase;
    double _beats;
    double _tempo;
    double _phaseContinous;
}

// Here you need to declare the input / output properties as dynamic as Quartz Composer will handle their implementation
@dynamic outputPlaying;
@dynamic outputBpm;
@dynamic outputPhase;
@dynamic outputBeats;
@dynamic outputPeers;
@dynamic outputQuantumPhase;
@dynamic outputMsecPerBeat;

@dynamic inputEnabled;
@dynamic inputPlay;
@dynamic inputQuanta;
@dynamic inputStartStopSync;

@synthesize RequestTempo;
@synthesize maximumBpm = _maximumBpm;


-(QCPlugInViewController *)createViewController {
    return [[QCAbletonLinkSettingsViewController alloc] initWithPlugIn:self viewNibName:@"QCAbletonLinkSettingsViewController"];
}
+ (NSDictionary *)attributes
{
    // Return a dictionary of attributes describing the plug-in (QCPlugInAttributeNameKey, QCPlugInAttributeDescriptionKey...).
    return @{QCPlugInAttributeNameKey:kQCPlugIn_Name, QCPlugInAttributeDescriptionKey:kQCPlugIn_Description, QCPlugInAttributeCopyrightKey:kQCPlugIn_Copyright, QCPlugInAttributeExamplesKey:@[@"AbletonLinkExample.qtz"], QCPlugInAttributeCategoriesKey:@[kQCPlugIn_Category, @"Source", @"oszillo"]};
}
//sorting pluginPropertyKeys
+(NSArray *)plugInKeys {
    //return [NSArray arrayWithObjects:kKeyPath1,kKeyPath2,nil];
    return [NSArray arrayWithObjects:kKeyPath1,nil];
}

+ (NSDictionary *)attributesForPropertyPortWithKey:(NSString *)key
{
    // Specify the optional attributes for property based ports (QCPortAttributeNameKey, QCPortAttributeDefaultValueKey...).
    if([key isEqualToString:@"inputEnabled"])
        return [NSDictionary
                dictionaryWithObjectsAndKeys:@"Enable", QCPortAttributeNameKey,
                [NSNumber numberWithBool:NO], QCPortAttributeDefaultValueKey,
                nil];
    if([key isEqualToString:@"inputPlay"])
        return [NSDictionary
                dictionaryWithObjectsAndKeys:@"Play", QCPortAttributeNameKey,
                [NSNumber numberWithBool:NO], QCPortAttributeDefaultValueKey,
                nil];
    if([key isEqualToString:@"inputQuanta"])
        return [NSDictionary
                dictionaryWithObjectsAndKeys:@"Quanta", QCPortAttributeNameKey,
                [NSNumber numberWithInt:1], QCPortAttributeMinimumValueKey,
                [NSNumber numberWithInt:16], QCPortAttributeMaximumValueKey,
                [NSNumber numberWithInt:4], QCPortAttributeDefaultValueKey,
                nil];
    if([key isEqualToString:@"inputStartStopSync"])
        return [NSDictionary
                dictionaryWithObjectsAndKeys:@"Sync to Start/Stop", QCPortAttributeNameKey,
                [NSNumber numberWithBool:NO], QCPortAttributeDefaultValueKey,
                nil];
    
    if([key isEqualToString:@"outputPlaying"]) return [NSDictionary dictionaryWithObjectsAndKeys: @"isPlaying", QCPortAttributeNameKey, nil];
    if([key isEqualToString:@"outputBpm"]) return [NSDictionary dictionaryWithObjectsAndKeys: @"Bpm", QCPortAttributeNameKey, nil];
    if([key isEqualToString:@"outputPhase"]) return [NSDictionary dictionaryWithObjectsAndKeys: @"Phase", QCPortAttributeNameKey, nil];
    if([key isEqualToString:@"outputBeats"]) return [NSDictionary dictionaryWithObjectsAndKeys: @"Beats", QCPortAttributeNameKey, nil];
    if([key isEqualToString:@"outputPeers"]) return [NSDictionary dictionaryWithObjectsAndKeys: @"Peers", QCPortAttributeNameKey, nil];
    if([key isEqualToString:@"outputQuantumPhase"]) return [NSDictionary dictionaryWithObjectsAndKeys: @"QuantumPhase", QCPortAttributeNameKey, nil];
    if([key isEqualToString:@"outputMsecPerBeat"]) return [NSDictionary dictionaryWithObjectsAndKeys: @"ms/Beat", QCPortAttributeNameKey, nil];
    
    return nil;
}

+ (QCPlugInExecutionMode)executionMode
{
    // Return the execution mode of the plug-in: kQCPlugInExecutionModeProvider, kQCPlugInExecutionModeProcessor, or kQCPlugInExecutionModeConsumer.
    return kQCPlugInExecutionModeProvider;
}

+ (QCPlugInTimeMode)timeMode
{
    // Return the time dependency mode of the plug-in: kQCPlugInTimeModeNone, kQCPlugInTimeModeIdle or kQCPlugInTimeModeTimeBase.
    //return kQCPlugInTimeModeTimeBase;
    //return kQCPlugInTimeModeIdle;
    return kQCPlugInTimeModeIdle;
}
-(void)dealloc {
    [self removeObserver:self forKeyPath:kKeyPath1];
    //[self removeObserver:self forKeyPath:kKeyPath2];
    //[super dealloc]; //dont super dealloc! bad idea.
}
- (instancetype)init
{
    self = [super init];
    if (self) {
        // Allocate any permanent resource required by the plug-in.

        _metronomeIsPlaying = NO;
        _isActive = NO;
        _isEnabled = NO;
        _playMetronome = NO;
        BOOL enabled  = self.inputEnabled;
        
        //_abletonLinkShared = [QCAbletonLinkObject sharedInstance];
        //_isPlaying = _abletonShared.isPlaying;
        _abletonLink = [[QCAbletonLinkObject alloc] init];
        
        [_abletonLink setEnabled:enabled];
        
        _quantum = _abletonLink.quantum;
        //quantum = state.audioPlatform.mEngine.quantum();
        //quantum = MAX( 1.0, MIN( 16.0, (double)self.inputQuanta));
        
        _startStopSyncOn = _abletonLink.isStartStopSyncEnabled;
        
        self.RequestTempo = _abletonLink.tempo;
        
        if (enabled && _abletonLink ) { //&& _abletonLink.running
            _bpm = _abletonLink.tempo;
        } else {
            _bpm = 120.0;
        }
        while (_bpm > 240) {
            _bpm = _bpm / 2;
        }
        
        [self addInputPortWithType:QCPortTypeNumber forKey:@"inputRequestTempo" withAttributes:[NSDictionary dictionaryWithObjectsAndKeys:@"RequestTempo", QCPortAttributeNameKey,
            [NSNumber numberWithDouble:20.0], QCPortAttributeMinimumValueKey,
            [NSNumber numberWithDouble:240.0], QCPortAttributeMaximumValueKey,
            [NSNumber numberWithDouble:_bpm], QCPortAttributeDefaultValueKey,nil]];
        [self addObserver:self forKeyPath:kKeyPath1 options:NSKeyValueObservingOptionNew context:NULL];

        
        //startStopSyncOn = state.audioPlatform.mEngine.isStartStopSyncEnabled();
        //linkTime = state.link.clock().micros();
        //uint64_t ticks = state.link.clock().ticks();
        //state.link.setNumPeersCallback(onNumberPeersChanged); //, (__bridge void *)(self)
        //Callback callb = *void;
        //ableton::Link::Measurement::Callback calb;
        //State().link.setStartStopCallback(onStartStopChanged);
        //state.link.startcallback = onStartStopChanged(bool isPlaying)
        //state.link.setTempoCallback(onSessionTempoChanged);
        
    }
    
    return self;
}


-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if([keyPath isEqual:kKeyPath1]){
        _maximumBpm = [[object valueForKey:keyPath] integerValue]==0 ? 240.0 : 999.0;
        if (_maximumBpm > 240.0) {
            [self removeInputPortForKey:@"inputRequestTempo"];
            [self addInputPortWithType:QCPortTypeNumber forKey:@"inputRequestTempo" withAttributes:[NSDictionary dictionaryWithObjectsAndKeys:@"RequestTempo", QCPortAttributeNameKey,
                            [NSNumber numberWithDouble:_bpm], QCPortAttributeDefaultValueKey,
                            [NSNumber numberWithDouble:20.0], QCPortAttributeMinimumValueKey,
                            [NSNumber numberWithDouble:999.0], QCPortAttributeMaximumValueKey,
                                                                                    nil]];
        } else {
            while (_bpm > 240) {
                _bpm = _bpm / 2;
            }
            [self removeInputPortForKey:@"inputRequestTempo"];
            [self addInputPortWithType:QCPortTypeNumber forKey:@"inputRequestTempo" withAttributes:[NSDictionary dictionaryWithObjectsAndKeys:@"RequestTempo", QCPortAttributeNameKey,
                              [NSNumber numberWithDouble:_bpm], QCPortAttributeDefaultValueKey,
                              [NSNumber numberWithDouble:20.0], QCPortAttributeMinimumValueKey,
                              [NSNumber numberWithDouble:240.0], QCPortAttributeMaximumValueKey,
                                                                                    nil]];
        }
    }
    /*
    if ([keyPath isEqual:kKeyPath2]){
        doTicks = [[object valueForKey:keyPath] integerValue]==0 ? NO : YES;
        if (doTicks) {
            [self addOutputPortWithType:QCPortTypeIndex forKey:@"outputTicks" withAttributes:[NSDictionary dictionaryWithObjectsAndKeys:@"Ticks", QCPortAttributeNameKey, nil]];
        } else {
            [self removeOutputPortForKey:@"outputTicks"];
        }
    } */
}
@end

@implementation LinkPlugIn (Execution)

- (BOOL)startExecution:(id <QCPlugInContext>)context
{
    // Called by Quartz Composer when rendering of the composition starts: perform any required setup for the plug-in.   [context logMessage:context.userInfo.description];
    // Return NO in case of fatal failure (this will prevent rendering of the composition to start).
    
    if (!_abletonLink) return NO;
    if (_playMetronome) [_abletonLink startMetronome];
    return YES;
}

- (void)enableExecution:(id <QCPlugInContext>)context
{
    // Called by Quartz Composer when the plug-in instance starts being used by Quartz Composer.
    _playMetronome = self.inputPlay;
    [_abletonLink startRunning];
    [_abletonLink setStartStopSync:_startStopSyncOn];
}

- (BOOL)execute:(id <QCPlugInContext>)context atTime:(NSTimeInterval)time withArguments:(NSDictionary *)arguments {
    if ([self didValueForInputKeyChange:@"inputStartStopSync"]){
        _startStopSyncOn = self.inputStartStopSync;
        [_abletonLink setStartStopSync:_startStopSyncOn];
        // NSLog(@"sync startstopCheckboxEnabled %d",_startStopSyncOn);
    }
    if ([self didValueForInputKeyChange:@"inputRequestTempo"]){
        self.RequestTempo = [[self valueForInputKey:@"inputRequestTempo"] doubleValue];
        _bpm = self.RequestTempo;
        [_abletonLink requestTempo:_bpm];
    }
    if ([self didValueForInputKeyChange:@"inputQuanta"]){
        _quantum = MAX( 1.0, MIN( 16.0, (double)self.inputQuanta));
        [_abletonLink setQuantum:_quantum];
    }
    if ([self didValueForInputKeyChange:@"inputPlay"]){
        _playMetronome = self.inputPlay;
        //if (_abletonLink.running) {
            if (_playMetronome) {
                [_abletonLink startMetronome];
            } else {
                [_abletonLink stopMetronome];
            }
        //}
    }
    
    if ([self didValueForInputKeyChange:@"inputEnabled"]){
        const bool bEnable = self.inputEnabled;
        [_abletonLink setEnabled:bEnable];
    }
    
    
    if (_abletonLink.isEnabled) {
        _metronomeIsPlaying = _abletonLink.metronomeIsPlaying;
        self.outputPlaying = _metronomeIsPlaying;
        self.outputPeers = _abletonLink.numPeers;
        _tempo = _abletonLink.tempo;
        self.outputBpm = _tempo;
        self.outputMsecPerBeat = 60000 / _tempo;
        if (_startStopSyncOn) { //_abletonLink.isStartStopSyncEnabled
            if (_abletonLink.isTransport) { //_abletonLink.isTransport
                [_abletonLink startMetronome];
                _metronomeIsPlaying = YES;
            } else {
                [_abletonLink stopMetronome];
                _metronomeIsPlaying = NO;
            }
        }
        if (_abletonLink.sessionIsPlaying) {
            _beats = _abletonLink.beats;
            _phase = _abletonLink.phase;
        } else {
            _phaseContinous = _abletonLink.phase;
        }
        self.outputBeats = _beats;
        self.outputPhase = _phase;
        self.outputQuantumPhase = _abletonLink.quantumPhase;
        //FIXME: doTicks implementation similar to Midi Ticks
        //if (doTicks) [self setValue:@(_abletonLink.ticks) forOutputKey:@"outputTicks"];
    }
    return YES;
}

- (void)disableExecution:(id <QCPlugInContext>)context
{
    // Called by Quartz Composer when the plug-in instance stops being used by Quartz Composer.
    [_abletonLink stopRunning];
}

- (void)stopExecution:(id <QCPlugInContext>)context
{
    // Called by Quartz Composer when rendering of the composition stops: perform any required cleanup for the plug-in.
    [_abletonLink closeLinkPeer];
}

@end

