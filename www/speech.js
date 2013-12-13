cordova.define("org.apache.cordova.plugin.speech", function(require, exports, module) {/**
 * 
 * Phonegap Version plugin for Android
 * Giuseppe Catalfamo 2013
 * gcatalfamo@gmail.com
 *
 */
var Speak = function() {};
var exec = require('cordova/exec');

Speak.prototype.say = function(successCallback, failureCallback, text, voice, pitch, speed) {
	var args = [text];
	if(voice !== undefined) { args.push(voice); }
	if(pitch !== undefined) { args.push(pitch); }
	if(speed !== undefined) { args.push(speed); }
    return exec(successCallback, failureCallback, 'Speak', 'say', args);
};

Speak.prototype.voices = function(successCallback, failureCallback) {
    return exec(successCallback, failureCallback, 'Speak', 'voices', []);
};

Speak.prototype.stopSpeaking = function(successCallback, failureCallback) {
    return exec(successCallback, failureCallback, 'Speak', 'stopSpeaking', []);
};


if(!window.plugins) {
    window.plugins = {};
}
if (!window.plugins.speech) {
    console.log("Init Version plugin to windows.plugins.speech");
    window.plugins.speech = new Speak();
}
});
