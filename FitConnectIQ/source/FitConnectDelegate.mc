import Toybox.WatchUi;
import Toybox.System;

class FitConnectDelegate extends WatchUi.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onSelect() {
        System.println("SEND DATA pressed");
        return true;
    }
}