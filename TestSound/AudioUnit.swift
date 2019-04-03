// Based on https://github.com/preble/SwiftToneAudioUnit

import AudioToolbox
import AudioUnit
import CoreAudio


class ToneGenerator {
    private var toneUnit: AudioUnit!
    
    init() {
        setupAudioUnit()
    }
    
    deinit {
        stop()
    }
    
    func setupAudioUnit() {
        
        // Configure the description of the output audio component we want to find:
        let componentSubtype: OSType

        componentSubtype = kAudioUnitSubType_DefaultOutput
        var defaultOutputDescription = AudioComponentDescription(componentType: kAudioUnitType_Output,
                                                                 componentSubType: componentSubtype,
                                                                 componentManufacturer: kAudioUnitManufacturer_Apple,
                                                                 componentFlags: 0,
                                                                 componentFlagsMask: 0)
        let defaultOutput = AudioComponentFindNext(nil, &defaultOutputDescription)!
        
        var err: OSStatus
        
        // Create a new instance of it in the form of our audio unit:
        err = AudioComponentInstanceNew(defaultOutput, &toneUnit)
        assert(err == noErr, "AudioComponentInstanceNew failed")
        
        // Set the render callback as the input for our audio unit:
        var renderCallbackStruct = AURenderCallbackStruct(inputProc: renderCallback,
                                                          inputProcRefCon: nil)
        err = AudioUnitSetProperty(toneUnit,
                                   kAudioUnitProperty_SetRenderCallback,
                                   kAudioUnitScope_Input,
                                   0,
                                   &renderCallbackStruct,
                                   UInt32(MemoryLayout<AURenderCallbackStruct>.size))
        assert(err == noErr, "AudioUnitSetProperty SetRenderCallback failed")
        
        // Set the stream format for the audio unit. That is, the format of the data that our render callback will provide.
        var streamFormat = AudioStreamBasicDescription(mSampleRate: Float64(sampleRate),
                                                       mFormatID: kAudioFormatLinearPCM,
                                                       mFormatFlags: kAudioFormatFlagsNativeFloatPacked|kAudioFormatFlagIsNonInterleaved,
                                                       mBytesPerPacket: 4 /*four bytes per float*/,
            mFramesPerPacket: 1,
            mBytesPerFrame: 4,
            mChannelsPerFrame: 1,
            mBitsPerChannel: 4*8,
            mReserved: 0)
        err = AudioUnitSetProperty(toneUnit,
                                   kAudioUnitProperty_StreamFormat,
                                   kAudioUnitScope_Input,
                                   0,
                                   &streamFormat,
                                   UInt32(MemoryLayout<AudioStreamBasicDescription>.size))
        assert(err == noErr, "AudioUnitSetProperty StreamFormat failed")
        
    }
    
    func start() {
        var status: OSStatus
        status = AudioUnitInitialize(toneUnit)
        status = AudioOutputUnitStart(toneUnit)
        assert(status == noErr)
    }
    
    func stop() {
        AudioOutputUnitStop(toneUnit)
        AudioUnitUninitialize(toneUnit)
    }
    
}

// Fixed values:
private let sampleRate = 44100
private let amplitude: Float = 1.0
private let frequency: Float = 440

/// Theta is changed over time as each sample is provided.
private var theta: Float = 0.0


private func renderCallback(inRefCon: UnsafeMutableRawPointer,
                            ioActionFlags: UnsafeMutablePointer<AudioUnitRenderActionFlags>,
                            inTimeStamp: UnsafePointer<AudioTimeStamp>,
                            inBusNumber: UInt32,
                            inNumberFrames: UInt32,
                            inData: UnsafeMutablePointer<AudioBufferList>?) -> OSStatus {
    guard let abl = UnsafeMutableAudioBufferListPointer(inData) else {
        fatalError("Wat")
    }
    let buffer = abl[0]
    let pointer: UnsafeMutableBufferPointer<Float32> = UnsafeMutableBufferPointer(buffer)
    for frame in 0..<inNumberFrames {
        let pointerIndex = pointer.startIndex.advanced(by: Int(frame))
        pointer[pointerIndex] = sin(theta) * amplitude
        theta += 2.0 * Float.pi * frequency / Float(sampleRate)
    }
    return noErr
}
