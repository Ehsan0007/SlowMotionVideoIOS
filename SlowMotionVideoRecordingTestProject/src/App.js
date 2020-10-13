import React, { Component } from 'react'
import { View, Text, TouchableOpacity, NativeModules } from 'react-native'
import SlowmoVideoRecorderManager from './index'

export default class App extends Component {

    slowMotionVideo = () => {
        // alert("Press")
        SlowmoVideoRecorderManager.launchSlowmoVideoRecorder((res)=>{
            console.log("CallBack Response", res)
        });
    }
    render() {
        return (
            <View style={{ flex: 1, justifyContent: 'center', alignItems: "center" }}>
                <TouchableOpacity onPress={() => this.slowMotionVideo()}>
                    <Text style={{ padding: 20, borderWidth: 1, borderColor: 'gray' }}>Slow Motion Video</Text>
                </TouchableOpacity>
            </View>
        )
    }
}