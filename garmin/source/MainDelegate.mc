import Toybox.Lang;
import Toybox.WatchUi;

class MainDelegate extends WatchUi.BehaviorDelegate {

    private var _view as MainView;

    function initialize(view as MainView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onTap(event as WatchUi.ClickEvent) as Boolean {
        promptForCode();
        return true;
    }

    function onSelect() as Boolean {
        promptForCode();
        return true;
    }

    function onMenu() as Boolean {
        promptForCode();
        return true;
    }

    private function promptForCode() as Void {
        var picker = new WatchUi.TextPicker("");
        WatchUi.pushView(picker, new CodePickerDelegate(_view), WatchUi.SLIDE_UP);
    }
}

class CodePickerDelegate extends WatchUi.TextPickerDelegate {

    private var _view as MainView;

    function initialize(view as MainView) {
        TextPickerDelegate.initialize();
        _view = view;
    }

    function onTextEntered(text as String, changed as Boolean) as Boolean {
        var code = text.toUpper();
        // Strip whitespace
        var clean = "";
        for (var i = 0; i < code.length(); i += 1) {
            var ch = code.substring(i, i + 1);
            if (ch.equals(" ") || ch.equals("\n") || ch.equals("\t")) {
                continue;
            }
            clean += ch;
        }
        if (clean.length() != 6) {
            _view.setStatus(WatchUi.loadResource(Rez.Strings.InvalidCode) as String);
            return true;
        }
        var fetcher = new FitFetcher(_view, clean);
        fetcher.start();
        return true;
    }

    function onCancel() as Boolean {
        return true;
    }
}
