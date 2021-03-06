/* Copyright 2016 Software Freedom Conservancy Inc.
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

private class Geary.SmtpOutboxFolderRoot : Geary.FolderRoot {
    public const string MAGIC_BASENAME = "$GearyOutbox$";
    
    public SmtpOutboxFolderRoot() {
        base(MAGIC_BASENAME, false, false);
    }
}

