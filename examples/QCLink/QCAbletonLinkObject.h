//
//  QCAbletonLinkObject.h
//  Link
//
//  Created by Frank Hofmann on 25.11.18.
//

#import <Foundation/Foundation.h>

// to use QCAbletonLink with sounding metronome instead of silent one set ABLLinkQuartzWithMetronome 1
#define ABLLinkQuartzWithMetronome 0
#if ABLLinkQuartzWithMetronome == 1
#include "AudioPlatform.hpp"
//#include "AudioPlatform_CoreAudio.hpp"
#else
#include "AudioPlatform_NoAudio.hpp"
#endif

#include <algorithm>
#include <atomic>
#include <chrono>
#include <iostream>
#include <thread>
#if defined(LINK_PLATFORM_UNIX)
#include <termios.h>
#endif


namespace QCAbletonLink
{
    struct State {
        
        std::atomic<bool> running;
        
        ableton::Link link;
        
        // to keep Link informed about AudioLatency its running with a silenced ZeroAudioEngine
        // this can be changed by setting ABLLinkQuartzWithMetronome 1
        ableton::linkaudio::AudioPlatform audioPlatform;
        
        // ableton::platforms::darwin::Clock clock;
        
        // this is how an Callback definition looks like
        //using Callback = std::function<void(std::atomic<bool>)>;
        
        State()
        : running(true)
        , link(120.)
        , audioPlatform(link)
        {
            link.enable(true);
        }
        
        ~State()
        { link.enable(false); }
    };
} // namespace

#define ABLLinkQuartzSingleton 0

typedef ableton::Link ABLLink;
typedef ableton::Link::SessionState ABLLinkSessionStateRef;

//FIXME: implement ABLLink.h similar to LinkKit for iOS for consistency of the API.
//typedef struct ABLLink *ABLLinkRef;

@interface QCAbletonLinkObject : NSObject

#if ABLLinkQuartzSingleton == 1
+(instancetype)sharedInstance;
#endif


-(ABLLinkSessionStateRef)sessionState;

-(NSUInteger)numPeers;

-(bool)running;

-(void)stopRunning;
-(void)startRunning;
-(void)setRunning:(bool)on;

-(void)closeLinkPeer;

-(void)startMetronome;
-(void)stopMetronome;
-(bool)metronomeIsPlaying;

-(bool)isEnabled;
-(void)setEnabled:(bool)bEnable;

-(double)quantum;
-(void)setQuantum:(double)quantum;

-(void)setStartStopSync:(bool)on;
-(bool)isStartStopSyncEnabled;

@property (nonatomic, getter=isTransport) bool transport;
-(bool)isTransport;
-(void)setTransport:(bool)on;

-(bool)sessionIsPlaying;

-(void)requestTempo:(double)bpm;
-(void)requestBeat:(double)beat;

-(double)tempo;
-(double)phase;
-(double)quantumPhase;
-(double)beats;

//FIXME: not done yet
-(uint64_t)ticks;

@end
