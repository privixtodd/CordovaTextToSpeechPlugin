
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <Cordova/CDVPlugin.h>

@interface CDVSpeak : CDVPlugin <CDVSpeak, AVAudioPlayerDelegate>
{
}

@property(nonatomic, readonly, getter=isSpeaking) BOOL speaking;
@property(nonatomic, readonly, getter=isPaused) BOOL paused;

/* AVSpeechUtterances are queued by default. If an AVSpeechUtterance is already enqueued or is speaking, this method will raise an exception. */

- (void)say:(CDVInvokedUrlCommand*)command;
- (void)stopSpeaking:(CDVInvokedUrlCommand*)command;
/*
- (void)pauseSpeaking:(CDVInvokedUrlCommand*)command;
- (void)isPaused:(CDVInvokedUrlCommand*)command;
- (void)resumeSpeaking:(CDVInvokedUrlCommand*)command;
*/
- (void)isSpeaking:(CDVInvokedUrlCommand*)command;
- (void)voices:(CDVInvokedUrlCommand*)command;

- (void)speakText:(NSString*)text withVoice:(NSString*)voice pitch:(float)pitch speed:(float)speed;
- (void)speakText:(NSString*)text pitch:(float)pitch speed:(float)speed;
- (void)speakText:(NSString*)text pitch:(float)pitch;
- (void)speakText:(NSString*)text speed:(float)speed;
- (void)speakText:(NSString*)text;

-(void)speakTextNow:(NSString *)text;
-(void)stopSpeakingAtBoundary:(NSInteger)b;
-(void)setPitch:(float)pitch variance:(float)variance speed:(float)speed;
-(void)setVoice:(NSString *)voicename;
@end


@end