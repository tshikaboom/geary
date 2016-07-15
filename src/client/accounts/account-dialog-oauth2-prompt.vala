/* Copyright 2016 Software Freedom Conservancy Inc.
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

using Soup;

// Confirmation of the deletion of an account
public class AccountDialogOauth2Prompt : Gtk.Box {
    private const string BASE_URL = "https://accounts.google.com/o/oauth2/v2/auth";

    private const string RESPONSE_TYPE = "response_type=code";
    private const string CLIENT_ID = ""; // fill me
    private const string CLIENT_SECRET = ""; // fill me
    private const string REDIRECT_URI = "http://127.0.0.1:6442";
    private const string SCOPE = "scope=https://mail.google.com/%20email%20profile";
    private const string STATE = "";

//    private Gtk.ScrolledWindow scrolled_window;
    private WebKit.WebView web_view;

    public GLib.Mutex token_mutex;

    public signal void prompt_accepted();

    private signal void prompt_continue(string url);

    public signal void token_added(string token);

    public AccountDialogOauth2Prompt() {
//        this.scrolled_window = new Gtk.ScrolledWindow(null, null);
        this.web_view = new WebKit.WebView();
        this.token_mutex = new GLib.Mutex();

//        scrolled_window.add(web_view);

//        pack_start(scrolled_window, true, true, 0);
        pack_start(web_view, true, true, 0);
        this.set_size_request(400, 400);
        prompt_continue.connect(on_continue);
        web_view.load_uri(construct_uri());
        show_all();


       web_view.navigation_requested.connect(on_redirect);
    }

    ~AccountDialogOauth2Prompt() {
        this.destroy();
    }

    private string construct_uri() {
        return BASE_URL + "?" + SCOPE + "&redirect_uri=" + REDIRECT_URI + "&" + RESPONSE_TYPE + "&client_id=" + CLIENT_ID;
        // + "&" + get_login_hint();
    }

    private string construct_continue(string url) {
        Soup.URI uri = new Soup.URI(url);
        string code = uri.get_query();
        code = code[5:code.length];

        return "code=" + code + "&" + CLIENT_ID + "&" + CLIENT_SECRET + "&" + REDIRECT_URI + "grant_type=authorization_code";
    }

    public string? get_token() {

        return null;
    }
    private void on_continue(string url) {
        web_view.load_uri(construct_continue(url));
    }


    private WebKit.NavigationResponse on_redirect(WebKit.WebFrame frame, WebKit.NetworkRequest request) {
        string url = request.get_uri();
        stdout.printf("redirected to %s\n", url);
        if (url.contains(REDIRECT_URI + "/")) {
            stdout.printf("We're in!\n");
            prompt_accepted();
            stdout.printf("code %s\n", construct_continue(url));
            Soup.Session session = new Soup.Session();
            Soup.Message message = new Soup.Message("POST /oauth2/v4/token HTTP/1.1", "www.googleapis.com");
            message.got_body.connect(on_got_body);
            message.set_request("application/x-www-form-urlencoded", Soup.MemoryUse.TEMPORARY, construct_continue(url).data);

            session.send_message(message);


            return WebKit.NavigationResponse.IGNORE;
        }

        stdout.printf("should we not be here?\n");
//        token_added(url);
        return WebKit.NavigationResponse.ACCEPT;
    }

    private void on_got_body(Soup.Message message) {
        stdout.printf("Testing for headers\n");
        if (message.response_headers.get_headers_type() == Soup.MessageHeadersType.RESPONSE) {
            stdout.printf("Normally it should be good?\n");
            stdout.printf("%s\n", (string) message.response_body.data);
        }
    }
}

