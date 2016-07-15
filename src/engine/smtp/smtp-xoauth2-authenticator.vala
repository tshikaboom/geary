/* Copyright 2016 Software Freedom Conservancy Inc.
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

/**
 * SASL's LOGIN authentication schema impemented as an {@link Authenticator}.
 *
 * LOGIN is obsolete but still widely in use and provided for backward compatibility.
 *
 * See [[https://tools.ietf.org/html/draft-murchison-sasl-login-00]]
 */

public class Geary.Smtp.XOAuth2Authenticator : Geary.Smtp.Authenticator {
    public XOAuth2Authenticator(Credentials credentials) {
        base ("XOAUTH2", credentials);
    }

    public override Request initiate() {
        return new Request(Command.AUTH, { "xoauth2" , credentials.get_gmail_style()});
    }

    public override Memory.Buffer? challenge(int step, Response response) throws SmtpError {
        switch (step) {
            case 0:
                stdout.printf("smtp: pushing out\n%s", credentials.get_gmail_style_string());
                return new Memory.StringBuffer(credentials.get_gmail_style());
            default:
                return null;
        }
    }
}

