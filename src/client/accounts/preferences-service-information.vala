/* Copyright 2017 Software Freedom Conservancy Inc.
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

/* A service implementation using GNOME Online Accounts.
 * This loads IMAP and SMTP settings from GOA.
 */
public class Geary.PreferencesServiceInformation : Geary.ServiceInformation {
    // This class is used to modify LocalServiceInformation from the client side.
    public PreferencesServiceInformation(
        Geary.Service service,
        string host,
        uint16 port,
        bool use_starttls,
        bool use_ssl,
        bool remember_password,
        Geary.Credentials credentials,
        string credentials_method,
        bool? smtp_noauth = null,
        bool? smtp_use_imap_credentials = null
        ) {
        this.service = service;
        this.host = host;
        this.port = port;
        this.use_starttls = use_starttls;
        this.use_ssl = use_ssl;
        this.remember_password = remember_password;
        this.credentials = credentials;
        this.credentials_method = credentials_method;
        if (this.service == Geary.Service.SMTP) {
            this.smtp_noauth = smtp_noauth;
            this.smtp_use_imap_credentials = smtp_use_imap_credentials;
        }

        this.credentials_method = METHOD_LIBSECRET;
    }

    public override void load_settings(KeyFile? key_file = null) throws Error {
    }

    public override void load_credentials(KeyFile? key_file = null, string? email_address = null) throws Error {
    }

    public override void save_settings(KeyFile? key_file = null) {
        switch (this.service) {
            case Geary.Service.IMAP:
                key_file.set_value(Geary.Config.GROUP, Geary.Config.IMAP_HOST, this.host);
                key_file.set_integer(Geary.Config.GROUP, Geary.Config.IMAP_PORT, this.port);
                key_file.set_boolean(Geary.Config.GROUP, Geary.Config.IMAP_SSL, this.use_ssl);
                key_file.set_boolean(Geary.Config.GROUP, Geary.Config.IMAP_STARTTLS, this.use_starttls);
                break;
            case Geary.Service.SMTP:
                key_file.set_value(Geary.Config.GROUP, Geary.Config.SMTP_HOST, this.host);
                key_file.set_integer(Geary.Config.GROUP, Geary.Config.SMTP_PORT, this.port);
                key_file.set_boolean(Geary.Config.GROUP, Geary.Config.SMTP_SSL, this.use_ssl);
                key_file.set_boolean(Geary.Config.GROUP, Geary.Config.SMTP_STARTTLS, this.use_starttls);
                key_file.set_boolean(Geary.Config.GROUP, Geary.Config.SMTP_USE_IMAP_CREDENTIALS, this.smtp_use_imap_credentials);
                key_file.set_boolean(Geary.Config.GROUP, Geary.Config.SMTP_NOAUTH, this.smtp_noauth);
                break;
        }
    }

}
