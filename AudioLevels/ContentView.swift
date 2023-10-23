//
//  ContentView.swift
//  AudioLevels
//
//  Created by Benjamin Luchterhand on 10/23/23.
//

import SwiftUI
import AudioToolbox
import CoreAudio
import Cocoa

struct AppVolume: Identifiable {
    var id = UUID()
    var name: String
    var volume: Float32
    var pid: pid_t
}

func getApplicationsAndVolumes() -> [AppVolume] {
    let workspace = NSWorkspace.shared
    let runningApplications = workspace.runningApplications
    
    var appVolumes: [AppVolume] = []

    for app in runningApplications {
        if app.activationPolicy == .regular {
            let appName = app.localizedName ?? app.bundleIdentifier ?? "Unknown"
            let appVolume = AppVolume(name: appName, volume: 0.5, pid: app.processIdentifier)
            appVolumes.append(appVolume)
        }
    }

    return appVolumes
}

func setApplicationVolume(appName: String, volume: Float32, pid: pid_t) {
    let osaScript = """
    set volume output volume \(volume * 100) -- Convert to percentage
    tell application "\(appName)" to set volume output volume \(volume * 100)
    """
    
    let script = NSAppleScript(source: osaScript)
    
    var errorInfo: NSDictionary?
    let _ = script?.executeAndReturnError(&errorInfo)
    
    if let error = errorInfo {
        print("Error setting volume: \(error)")
    }
}

func setSystemVolume(volume: Float32) {
    var defaultOutputDeviceID = AudioDeviceID(0)
    var defaultOutputDeviceIDSize = UInt32(MemoryLayout.size(ofValue: defaultOutputDeviceID))
    
    var getDefaultOutputDevicePropertyAddress = AudioObjectPropertyAddress(
        mSelector: kAudioHardwarePropertyDefaultOutputDevice,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: AudioObjectPropertyElement(kAudioObjectPropertyElementMain))

    let status1 = AudioObjectGetPropertyData(
        AudioObjectID(kAudioObjectSystemObject),
        &getDefaultOutputDevicePropertyAddress,
        0,
        nil,
        &defaultOutputDeviceIDSize,
        &defaultOutputDeviceID)
    
    var volume = Float32(0.50)
    var volumeSize = UInt32(MemoryLayout.size(ofValue: volume))

    var volumePropertyAddress = AudioObjectPropertyAddress(
        mSelector: kAudioHardwareServiceDeviceProperty_VirtualMainVolume,
        mScope: kAudioDevicePropertyScopeOutput,
        mElement: kAudioObjectPropertyElementMain)

    let status2 = AudioObjectSetPropertyData(
        defaultOutputDeviceID,
        &volumePropertyAddress,
        0,
        nil,
        volumeSize,
        &volume)
}

func getVolume() -> Float32 {
    var defaultOutputDeviceID = AudioDeviceID(0)
    var volume = Float32(0.0)
    var volumeSize = UInt32(MemoryLayout.size(ofValue: volume))

    var volumePropertyAddress = AudioObjectPropertyAddress(
        mSelector: kAudioHardwareServiceDeviceProperty_VirtualMainVolume,
        mScope: kAudioDevicePropertyScopeOutput,
        mElement: kAudioObjectPropertyElementMain)

    let status3 = AudioObjectGetPropertyData(
        defaultOutputDeviceID,
        &volumePropertyAddress,
        0,
        nil,
        &volumeSize,
        &volume)

    return volume
}


struct ContentView: View {
    @State private var currentVolume: Float32 = 0.0
    @State private var appVolumes: [AppVolume] = getApplicationsAndVolumes()

    var body: some View {
        VStack {
            List {
                ForEach($appVolumes) { $appVolume in
                    HStack {
                        Text(appVolume.name)
                            .frame(width: 150)
                        Slider(value: $appVolume.volume, in: 0.0...1.0, step: 0.05)
                            .frame(width: 300)
                            .onChange(of: appVolume.volume) { newValue in
                                setApplicationVolume(appName: appVolume.name, volume: newValue, pid: appVolume.pid)
                            }
                    }
                }
            }
            .navigationTitle("Audio Levels")
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
