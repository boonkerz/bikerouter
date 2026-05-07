import Toybox.Application.Storage;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class MainView extends WatchUi.View {

    private var _status as String = "";
    private var _lastCode as String? = null;

    function initialize() {
        View.initialize();
        var stored = Storage.getValue("lastCode");
        if (stored instanceof String) {
            _lastCode = stored;
        }
    }

    function setStatus(text as String) as Void {
        _status = text;
        WatchUi.requestUpdate();
    }

    function setLastCode(code as String) as Void {
        _lastCode = code;
        Storage.setValue("lastCode", code);
        WatchUi.requestUpdate();
    }

    function onLayout(dc as Dc) as Void {}

    function onUpdate(dc as Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        // Title
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, 16, Graphics.FONT_MEDIUM,
            WatchUi.loadResource(Rez.Strings.Title) as String,
            Graphics.TEXT_JUSTIFY_CENTER);

        // Big tap-target rectangle in the middle
        var btnY = (h / 2) - 40;
        dc.setColor(Graphics.COLOR_DK_BLUE, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(20, btnY, w - 40, 80, 12);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, btnY + 24, Graphics.FONT_LARGE,
            WatchUi.loadResource(Rez.Strings.EnterCode) as String,
            Graphics.TEXT_JUSTIFY_CENTER);

        // Last code
        if (_lastCode != null) {
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(w / 2, btnY + 90, Graphics.FONT_TINY,
                (WatchUi.loadResource(Rez.Strings.LastCode) as String) + ": " + _lastCode,
                Graphics.TEXT_JUSTIFY_CENTER);
        }

        // Status line at bottom
        if (_status.length() > 0) {
            dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
            dc.drawText(w / 2, h - 28, Graphics.FONT_XTINY, _status,
                Graphics.TEXT_JUSTIFY_CENTER);
        }
    }

    function getButtonRect() as [Number, Number, Number, Number] {
        var w = 246;
        var h = 322;
        var btnY = (h / 2) - 40;
        return [20, btnY, w - 40, 80];
    }
}
