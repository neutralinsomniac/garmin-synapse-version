import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Communications;
import Toybox.Timer;

class JsonTransaction {
    public var version;

    // set up the response callback function
    function localOnReceive(responseCode as Number, data as Dictionary?) as Void {
        if (responseCode == 200) {
            self.version = Lang.format("L: v$1$", [data["server"]["version"]]);
        } else {
            self.version = Lang.format("$1$", [responseCode.format("%d")]);
        }

    }

    function remoteOnReceive(responseCode as Number, data as Dictionary?) as Void {
        if (responseCode == 200) {
            self.version = Lang.format("R: $1$", [data["tag_name"]]);
        } else {
            self.version = Lang.format("$1$", [responseCode.format("%d")]);
        }
    }

    function makeRequest(url, remote) as Void {
        var params = {                                              // set the parameters
        };

        var options = {                                             // set the options
            :method => Communications.HTTP_REQUEST_METHOD_GET,      // set HTTP method
            // set response type
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };

        var responseCallback;
        if (remote) {
            responseCallback = method(:remoteOnReceive);
        } else {
            responseCallback = method(:localOnReceive);
        }
        // Make the Communications.makeWebRequest() call
        Communications.makeWebRequest(url, params, options, responseCallback);
    }
}

class synapseView extends WatchUi.View {
    var localjs;
    var remotejs;

    function timerCallback() {
        WatchUi.requestUpdate();
    }

    function initialize() {
        View.initialize();
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.MainLayout(dc));
 
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
        self.localjs = new JsonTransaction();
        self.localjs.makeRequest("https://pintobyte.com/_matrix/federation/v1/version", false);
        self.remotejs = new JsonTransaction();
        self.remotejs.makeRequest("https://api.github.com/repos/matrix-org/synapse/releases/latest", true);
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        var localVersionView = View.findDrawableById("LocalVersionLabel") as Text;
        var remoteVersionView = View.findDrawableById("RemoteVersionLabel") as Text;

        if (self.localjs.version) {
            localVersionView.setText(self.localjs.version);
        }

        if (self.remotejs.version) {
            remoteVersionView.setText(self.remotejs.version);
        }

        if ((self.remotejs.version == null) || (self.localjs.version == null)) {
            var myTimer = new Timer.Timer();
            myTimer.start(method(:timerCallback), 100, false);
        }
    
        // Call the parent onUpdate function to redraw the layout
        View.onUpdate(dc);
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
    }

}
