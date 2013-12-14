#import "CDVSpeak.h"
#import "flite.h"

cst_voice *register_cmu_us_kal();
cst_voice *register_cmu_us_kal16();
cst_voice *register_cmu_us_rms();
cst_voice *register_cmu_us_awb();
cst_voice *register_cmu_us_slt();
cst_wave *sound;
cst_voice *voice;

@implementation CDVSpeak

@synthesize queue;
@synthesize audioPlayer;

- (id)initWithWebView:(UIWebView*)theWebView
{
    if((self = [super initWithWebView:theWebView]))
    {
        flite_init();
        // Set a default voice
        //voice = register_cmu_us_kal();
        //voice = register_cmu_us_kal16();
        //voice = register_cmu_us_rms();
        //voice = register_cmu_us_awb();
        //voice = register_cmu_us_slt();
        [self setVoice:@"cmu_us_kal"];
        self.queue = [NSMutableArray arrayWithCapacity: 10];
    }
    return self;
}

- (void)say:(CDVInvokedUrlCommand*)command
{
    NSString* text = [command argumentAtIndex:0];
    NSString* vox = [command argumentAtIndex:1 withDefault: @"cmu_us_kal"];
    float pitch = [[command argumentAtIndex:2 withDefault:[NSNumber numberWithFloat: 1.0]] floatValue];
    float speed = [[command argumentAtIndex:3 withDefault:[NSNumber numberWithFloat: 1.0]] floatValue];

    [self speakText: text withVoice: vox pitch: pitch speed: speed];
    CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

- (void)stopSpeaking:(CDVInvokedUrlCommand*)command
{
	self.queue = [NSMutableArray new];
	[self stopSpeakingAtBoundary:0];
	CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)isSpeaking:(CDVInvokedUrlCommand*)command
{
    BOOL speaking = ([self.queue count] > 0 || self.audioPlayer != nil);
	CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool: speaking];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];	
}

/*
- (void)pauseSpeaking:(CDVInvokedUrlCommand*)command;
- (void)resumeSpeaking:(CDVInvokedUrlCommand*)command;
- (void)isPaused:(CDVInvokedUrlCommand*)command;
*/

- (void)voices:(CDVInvokedUrlCommand*)command
{
	NSArray* voices = @[ @"cmu_us_kal", @"cmu_us_rms", @"cmu_us_awb", @"cmu_us_slt" ];

    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:voices];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)speakText:(NSString*)text withVoice:(NSString*)voice pitch:(float)pitch speed:(float)speed
{
    BOOL wasSpeaking = self.isSpeaking;
	[self.queue addObject: @{
		@"text": text, 
		@"voice": voice ? voice : @"cmu_us_kal", 
		@"pitch": [NSNumber numberWithFloat:pitch], 
		@"speed": [NSNumber numberWithFloat: speed]}];

	if(!wasSpeaking)
	{
		[self audioPlayerDidFinishPlaying:nil successfully:YES];
	}
}

- (void)speakText:(NSString*)text pitch:(float)pitch speed:(float)speed
{
	[self speakText:text withVoice: @"cmu_us_kal" pitch: pitch speed: speed];
}

- (void)speakText:(NSString*)text pitch:(float)pitch
{
	[self speakText:text pitch: pitch speed: 1.0];
}

- (void)speakText:(NSString*)text speed:(float)speed
{
	[self speakText:text pitch: 1.0 speed: speed];
}

- (void)speakText:(NSString*)text
{
	[self speakText:text speed: 1.0];
}

/* These methods will operate on the speech utterance that is speaking. Returns YES if it succeeds, NO for failure. */

-(void)speakTextNow:(NSString *)text
{
	NSMutableString *cleanString;
	cleanString = [NSMutableString stringWithString:@""];
	if([text length] > 1)
	{
		int x = 0;
		while (x < [text length])
		{
			unichar ch = [text characterAtIndex:x];
			[cleanString appendFormat:@"%c", ch];
			x++;
		}
	}
	if(cleanString == nil)
	{	// string is empty
		cleanString = [NSMutableString stringWithString:@""];
	}
	sound = flite_text_to_wave([cleanString UTF8String], voice);
	
	
	/*
	// copy sound into soundObj -- doesn't yet work -- can anyone help fix this?
	soundObj = [NSData dataWithBytes:sound length:sizeof(sound)]; // find out wy this doesn't work
	NSError *sAudioPlayerErr;
	AVAudioPlayer *sAudioPlayer = [[AVAudioPlayer alloc] initWithData:soundObj error:&sAudioPlayerErr];
	NSLog(@"%@", [sAudioPlayerErr localizedDescription]);
	[sAudioPlayer setDelegate:self];
	[sAudioPlayer prepareToPlay];
	[sAudioPlayer play];
	NSLog(@"%@", [sAudioPlayerErr localizedDescription]);
	*/
	
	NSArray *filePaths = NSSearchPathForDirectoriesInDomains (NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *recordingDirectory = [filePaths objectAtIndex: 0];
	// Pick a file name
	NSString *tempFilePath = [NSString stringWithFormat: @"%@/%s", recordingDirectory, "temp.wav"];
	// save wave to disk
	char *path;	
	path = (char*)[tempFilePath UTF8String];
	cst_wave_save_riff(sound, path);
	// Play the sound back.
	NSError *err;
	[self.audioPlayer stop];
	self.audioPlayer =  [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:tempFilePath] error:&err];
	[self.audioPlayer setDelegate:self];
	//[audioPlayer prepareToPlay];
	[self.audioPlayer play];
	// Remove file
	[[NSFileManager defaultManager] removeItemAtPath:tempFilePath error:nil];
	delete_wave(sound);
	
}

-(void)setPitch:(float)pitch variance:(float)variance speed:(float)speed
{
	feat_set_float(voice->features,"int_f0_target_mean", pitch);
	feat_set_float(voice->features,"int_f0_target_stddev",variance);
	feat_set_float(voice->features,"duration_stretch",speed); 
}

-(void)setVoice:(NSString *)voicename
{
	if([voicename isEqualToString:@"cmu_us_kal"]) {
		voice = register_cmu_us_kal();
	}
	else if([voicename isEqualToString:@"cmu_us_kal16"]) {
		voice = register_cmu_us_kal16();
	}
	else if([voicename isEqualToString:@"cmu_us_rms"]) {
		voice = register_cmu_us_rms();
	}
	else if([voicename isEqualToString:@"cmu_us_awb"]) {
		voice = register_cmu_us_awb();
	}
	else if([voicename isEqualToString:@"cmu_us_slt"]) {
		voice = register_cmu_us_slt();
	}
    [self setPitch:1.0 variance:1.0 speed:1.0];
}

-(void)stopSpeakingAtBoundary:(NSInteger)boundary
{
	[self.audioPlayer stop];
    self.queue = [NSMutableArray new];
}

-(BOOL)isSpeaking
{
	return [self.audioPlayer isPlaying] || [self.queue count] > 0;
}

-(BOOL)isPaused
{
	return NO;
}

// AVAudioPlayer Delegate Methods
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
	self.audioPlayer = nil;
	if([self.queue count] > 0)
	{
		NSDictionary* dict = [self.queue objectAtIndex: 0];
		[self.queue removeObjectAtIndex: 0];
		[self setVoice: dict[@"voice"]];
		float pitch = [dict[@"pitch"]floatValue];
		float speed = [dict[@"speed"]floatValue];
		feat_set_float(voice->features,"int_f0_target_mean", pitch);
		feat_set_float(voice->features,"duration_stretch",speed);
		[self speakTextNow: dict[@"text"]];
	}
}

@end