import Toybox.Communications;
import Toybox.Lang;
import Toybox.WatchUi;

class FitFetcher {

    private var _view as MainView;
    private var _code as String;

    function initialize(view as MainView, code as String) {
        _view = view;
        _code = code;
    }

    function start() as Void {
        _view.setStatus(WatchUi.loadResource(Rez.Strings.Fetching) as String);
        var url = "https://wegwiesel.app/api/share/" + _code + "/course.fit";
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_FIT,
            :fileDownloadProgressCallback => method(:onProgress)
        };
        Communications.makeWebRequest(url, {}, options, method(:onResponse));
    }

    function onProgress(received as Number, total as Number) as Void {
        // Optional: show progress; courses are tiny so usually one tick suffices.
    }

    function onResponse(responseCode as Number, data as Dictionary?) as Void {
        if (responseCode == 200) {
            _view.setLastCode(_code);
            var saved = WatchUi.loadResource(Rez.Strings.Saved) as String;
            var tipTpl = WatchUi.loadResource(Rez.Strings.Tip) as String;
            var tip = substitute(tipTpl, "{code}", _code);
            _view.setStatus(saved + " — " + tip);
        } else if (responseCode == 404) {
            _view.setStatus(WatchUi.loadResource(Rez.Strings.ErrorNotFound) as String);
        } else if (responseCode < 0) {
            // BLE/WiFi/transport-level error.
            _view.setStatus(WatchUi.loadResource(Rez.Strings.ErrorNetwork) as String);
        } else {
            var tpl = WatchUi.loadResource(Rez.Strings.ErrorGeneric) as String;
            _view.setStatus(substitute(tpl, "{error}", responseCode.toString()));
        }
    }

    private function substitute(template as String, key as String, value as String) as String {
        var idx = template.find(key);
        if (idx == null) {
            return template;
        }
        return template.substring(0, idx) + value + template.substring(idx + key.length(), template.length());
    }
}
