import Toybox.Communications;
import Toybox.System;


class FitConnectTransmitCallback extends Communications.ConnectionListener {

    hidden var mView;

    function initialize(view) {
        ConnectionListener.initialize();
        mView = view;
    }

    function onComplete() {
        System.println("Transmit complete");
        mView.onTransmitFinished(true);
    }

    function onError() {
        System.println("Transmit error");
        mView.onTransmitFinished(false);
    }
}