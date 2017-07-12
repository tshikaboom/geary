/* Copyright 2016 Software Freedom Conservancy Inc.
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

public abstract class Geary.ServiceInformation : GLib.Object {
    public string host { get; set; default = ""; }
    public uint16 port { get; set; }
    public bool use_starttls { get; set; default = false; }
    public bool use_ssl { get; set; default = true; }
    public bool remember_password { get; set; default = false; }
    public Geary.Credentials credentials { get; set; default = new Geary.Credentials(null, null); }
    public Geary.Service service { get; set; }
    public Geary.CredentialsMediator? mediator { get; set; default = null; }

    public enum auth_method {
        LIBSECRET,
        GOA,
        NONE;

        public string to_string() {
            switch(this) {
                case LIBSECRET:
                    return "libsecret";

                case GOA:
                    return "goa";

                case NONE:
                    return "none";
            }
            return "";
        }
    }

    public auth_method method { get; set; default = ServiceInformation.auth_method.NONE; }

    // Used with SMTP servers
    public bool smtp_noauth { get; set; default = false; }
    public bool smtp_use_imap_credentials { get; set; default = false; }

    public abstract void load_settings() throws Error;

    public abstract void load_credentials() throws Error;

    public abstract void save_settings(ref KeyFile key_file);

    public ServiceInformation.with_settings(Geary.ServiceInformation from) {
        this.host = from.host;
        this.port = from.port;
        this.use_starttls = from.use_starttls;
        this.use_ssl = from.use_ssl;
        this.remember_password = from.remember_password;
        this.credentials = from.credentials;
        this.service = from.service;
        this.smtp_noauth = from.smtp_noauth;
        this.smtp_use_imap_credentials = from.smtp_use_imap_credentials;
    }

    public void set_password(string password) {
        this.credentials = new Credentials(this.credentials.user, password);
    }
}
