
class FitConnectTransmitCallback extends Toybox.Communications.ConnectionListener {

    function initialize() {
        ConnectionListener.initialize();
    }

    function onComplete() {
        System.println("Transmit complete");
    }

    function onError() {
        System.println("Transmit error");
    }
}