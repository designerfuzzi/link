//
//  LinkPlugIn.h
//  Link
//
//  Created by Frank Hofmann on 23.11.18.
//

#import <Quartz/Quartz.h>
#import "QCAbletonLinkSettingsViewController.h"

@interface LinkPlugIn : QCPlugIn {
    Float64 _bpm;
    BOOL _isActive;
    BOOL _metronomeIsPlaying;
    BOOL _isEnabled;
    BOOL doTicks;
}

// Declare here the properties to be used as input and output ports for the plug-in e.g.
//@property double inputFoo;
//@property (copy) NSString* outputBar;

@property double maximumBpm;
@property BOOL Allow999;
//@property BOOL Ticks;

@property BOOL outputPlaying;
@property double outputBpm;
@property double outputPhase;
@property double outputBeats;
@property unsigned long outputPeers;
@property double outputQuantumPhase;
@property double outputMsecPerBeat;

@property BOOL inputEnabled;
@property BOOL inputPlay;
@property NSUInteger inputQuanta;
@property double RequestTempo;
@property BOOL inputStartStopSync;

@end


