/* Copyright 2016 Software Freedom Conservancy Inc.
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

public abstract class Geary.ServiceInformation : GLib.Object {
    public string host { get; protected set; default = ""; }
    public uint16 port { get; protected set; }
    public bool use_starttls { get; protected set; default = false; }
    public bool use_ssl { get; protected set; default = true; }
    public bool remember_password { get; protected set; default = false; }
    public Geary.Credentials credentials { get; protected set; default = new Geary.Credentials(null, null); }
    public Geary.Service service { get; protected set; }

    // Used with SMTP servers
    public bool smtp_noauth { get; protected set; default = false; }
    public bool smtp_use_imap_credentials { get; protected set; default = false; }

    public abstract void load_settings() throws Error;

    public abstract void load_credentials() throws Error;

    public abstract void save_settings(ref KeyFile key_file);
}
