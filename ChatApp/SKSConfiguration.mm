//
//  SKSConfiguration.mm
//  SpeechKitSample
//
//  All Nuance Developers configuration parameters can be set here.
//
//  Copyright (c) 2015 Nuance Communications. All rights reserved.
//

#import "SKSConfiguration.h"

// All fields are required.
// Your credentials can be found in your Nuance Developers portal, under "Manage My Apps".
NSString* SKSAppKey = @"0fd990fee5b634a6646246b0073b46ac9b28e116c2aebd14d9e91443ee536afd2dfbfb12b130b81592fec69a3a0c46d53427ebf7d6a80baf921ff280735d7da0";
NSString* SKSAppId = @"NMDPPRODUCTION_Dominick_Oddo_AvaChallenge_20160613182750";
NSString* SKSServerHost = @"jge.nmdp.nuancemobility.net";
NSString* SKSServerPort = @"443";

NSString* SKSLanguage = @"!LANGUAGE!";

NSString* SKSServerUrl = [NSString stringWithFormat:@"nmsps://%@@%@:%@", SKSAppId, SKSServerHost, SKSServerPort];

// Only needed if using NLU/Bolt
NSString* SKSNLUContextTag = @"!NLU_CONTEXT_TAG!";

