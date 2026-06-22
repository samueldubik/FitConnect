import Toybox.WatchUi;
import Toybox.System;

class FitConnectIQDelegate extends WatchUi.BehaviorDelegate {

    hidden var mView;

    function initialize(view) {
        BehaviorDelegate.initialize();
        mView = view;
    }

    function onSelect() {
        System.println("SELECT pressed");

        return sendPayload();
    }

    function onTap(clickEvent) {
        System.println("SCREEN tapped");

        return sendPayload();
    }

    hidden function sendPayload() {

        if (mView != null) {
            mView.collectData();
        }

        return true;
    }

    function onBack() {
        return false;
    }
}
