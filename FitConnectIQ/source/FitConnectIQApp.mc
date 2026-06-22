import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Communications;
import Toybox.System;

class FitConnectIQApp extends Application.AppBase {

    hidden var mView;

    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
    }

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {
    }

    // Return the initial view of your application here
function getInitialView() {
    mView = new FitConnectIQView();

    Communications.registerForPhoneAppMessages(
        method(:onPhoneMessage)
    );

    return [ mView, new FitConnectIQDelegate(mView) ];
}

function onPhoneMessage(message as Communications.PhoneAppMessage) as Void {
    System.println("Phone message received:");
    System.println(message.data);

    if (mView != null) {
        mView.onReceivePhoneMessage(message.data);
    }
}
}

function getApp() as FitConnectIQApp {
    return Application.getApp() as FitConnectIQApp;
}
