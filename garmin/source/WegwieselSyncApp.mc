import Toybox.Application;
import Toybox.Communications;
import Toybox.Lang;
import Toybox.WatchUi;

class WegwieselSyncApp extends Application.AppBase {

    private var _view as MainView?;

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Dictionary?) as Void {
        Communications.registerForPhoneAppMessages(method(:onPhoneMessage));
    }

    function onStop(state as Dictionary?) as Void {}

    function getInitialView() as [Views] or [Views, InputDelegates] {
        _view = new MainView();
        var delegate = new MainDelegate(_view);
        return [_view, delegate];
    }

    // Phone-app message: { "code": "ABC123" } sent from the Wegwiesel
    // iOS/Android app via the Connect IQ Mobile SDK. We accept either
    // a Dictionary payload or — for resilience — a plain String code.
    function onPhoneMessage(msg as Communications.PhoneAppMessage) as Void {
        if (_view == null) {
            return;
        }
        var data = msg.data;
        var code = null;
        if (data instanceof Lang.Dictionary) {
            var raw = data["code"];
            if (raw instanceof Lang.String) {
                code = raw;
            }
        } else if (data instanceof Lang.String) {
            code = data;
        }
        if (code == null || code.length() != 6) {
            return;
        }
        var fetcher = new FitFetcher(_view, code.toUpper());
        fetcher.start();
    }
}

function getApp() as WegwieselSyncApp {
    return Application.getApp() as WegwieselSyncApp;
}
