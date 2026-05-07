import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class WegwieselSyncApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Dictionary?) as Void {}

    function onStop(state as Dictionary?) as Void {}

    function getInitialView() as [Views] or [Views, InputDelegates] {
        var view = new MainView();
        var delegate = new MainDelegate(view);
        return [view, delegate];
    }
}

function getApp() as WegwieselSyncApp {
    return Application.getApp() as WegwieselSyncApp;
}
