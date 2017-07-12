/* Copyright 2016 Software Freedom Conservancy Inc.
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

public class AccountLoader {

    public static async void add_existing_accounts_async(Cancellable? cancellable = null) throws Error {
        try {
            Geary.Engine.instance.user_data_dir.make_directory_with_parents(cancellable);
        } catch (IOError e) {
            if (!(e is IOError.EXISTS))
                throw e;
        }

        FileEnumerator enumerator
            = yield Geary.Engine.instance.user_config_dir.enumerate_children_async("standard::*",
                FileQueryInfoFlags.NONE, Priority.DEFAULT, cancellable);

        Gee.List<Geary.AccountInformation> account_list = new Gee.ArrayList<Geary.AccountInformation>();

        Geary.CredentialsMediator mediator = new SecretMediator();
        stdout.printf("secretmediator @ %p\n", mediator);
        for (;;) {
            List<FileInfo> info_list;
            try {
                info_list = yield enumerator.next_files_async(1, Priority.DEFAULT, cancellable);
            } catch (Error e) {
                debug("Error enumerating existing accounts: %s", e.message);
                break;
            }

            if (info_list.length() == 0)
                break;

            FileInfo info = info_list.nth_data(0);
            if (info.get_file_type() == FileType.DIRECTORY) {
//                try {
                    string id = info.get_name();
                    account_list.add(
                        load_from_file(id)
                    );
/*                } catch (Error err) {
                    warning("Ignoring empty/bad config in %s: %s",
                            info.get_name(), err.message);
                } */
            }
        }

        foreach(Geary.AccountInformation info in account_list)
            Geary.Engine.instance.add_account(info);
     }

    public static async void add_goa_accounts_async(Cancellable? cancellable = null) throws Error {
        Goa.Client goa_client = new Goa.Client.sync();
        GLib.List<Goa.Object> list = goa_client.get_accounts();
        Goa.Account account;
        Goa.PasswordBased password;
        Goa.Mail mail;
        Goa.Object account_object;
        Geary.AccountInformation info;
        Gee.List<Geary.AccountInformation> account_list = new Gee.ArrayList<Geary.AccountInformation>();
        stdout.printf("goa list length is %u\n", list.length());
        Geary.CredentialsMediator mediator = null;
        for (int i=0; i < list.length(); i++) {
            account_object = list.nth_data(i);
            mail = account_object.get_mail();
            account = account_object.get_account();
            password = account_object.get_password_based();
            if (mail != null && password != null) {
                stdout.printf("adding goa account %s email %s\n", account.id, mail.email_address);
                mediator = new GOAMediator(password);
                info = new Geary.AccountInformation(account.id,
                               Geary.Engine.instance.user_config_dir.get_child(account.id),
                               Geary.Engine.instance.user_data_dir.get_child(account.id),
                               new Geary.GOAServiceInformation(Geary.Service.IMAP, mediator, mail),
                               new Geary.GOAServiceInformation(Geary.Service.SMTP, mediator, mail));
                load_from_goa(mail, info);
                account_list.add(info);
                stdout.printf("added goa account w/ mediator %p\n", mediator);
            }
        }

        foreach (Geary.AccountInformation tmp in account_list)
            Geary.Engine.instance.add_account(tmp);
    }

    /**
     * Loads an account info from a config directory.
     *
     * Throws an error if the config file was not found, could not be
     * parsed, or doesn't have all required fields.
     */
    public static Geary.AccountInformation load_from_file(string id)
        throws Error {

        Geary.CredentialsMediator mediator = new SecretMediator();

        Geary.AccountInformation info = new Geary.AccountInformation(id,
                            Geary.Engine.instance.user_config_dir.get_child(id),
                            Geary.Engine.instance.user_data_dir.get_child(id),
                            new Geary.LocalServiceInformation(Geary.Service.IMAP, Geary.Engine.instance.user_config_dir.get_child(id), mediator),
                            new Geary.LocalServiceInformation(Geary.Service.SMTP, Geary.Engine.instance.user_config_dir.get_child(id), mediator));

        KeyFile key_file = new KeyFile();
        key_file.load_from_file(info.file.get_path() ?? "", KeyFileFlags.NONE);

        // This is the only required value at the moment?
        string primary_email = key_file.get_value(Geary.Config.GROUP, Geary.Config.PRIMARY_EMAIL_KEY);
        string real_name = Geary.Config.get_string_value(key_file, Geary.Config.GROUP, Geary.Config.REAL_NAME_KEY);

        info.primary_mailbox = new Geary.RFC822.MailboxAddress(real_name, primary_email);
        info.nickname = Geary.Config.get_string_value(key_file, Geary.Config.GROUP, Geary.Config.NICKNAME_KEY);

        // Store alternate emails in a list of case-insensitive strings
        Gee.List<string> alt_email_list = Geary.Config.get_string_list_value(key_file, Geary.Config.GROUP, Geary.Config.ALTERNATE_EMAILS_KEY);
        if (alt_email_list.size != 0) {
            foreach (string alt_email in alt_email_list) {
                Geary.RFC822.MailboxAddresses mailboxes = new Geary.RFC822.MailboxAddresses.from_rfc822_string(alt_email);
                foreach (Geary.RFC822.MailboxAddress mailbox in mailboxes.get_all())
                info.add_alternate_mailbox(mailbox);
            }
        }

        info.imap.load_credentials();
        info.smtp.load_credentials();

        info.service_provider = Geary.ServiceProvider.from_string(
            Geary.Config.get_string_value(
                key_file, Geary.Config.GROUP, Geary.Config.SERVICE_PROVIDER_KEY, Geary.ServiceProvider.GMAIL.to_string()));
        info.prefetch_period_days = Geary.Config.get_int_value(
            key_file, Geary.Config.GROUP, Geary.Config.PREFETCH_PERIOD_DAYS_KEY, info.prefetch_period_days);
        info.save_sent_mail = Geary.Config.get_bool_value(
            key_file, Geary.Config.GROUP, Geary.Config.SAVE_SENT_MAIL_KEY, info.save_sent_mail);
        info.ordinal = Geary.Config.get_int_value(
            key_file, Geary.Config.GROUP, Geary.Config.ORDINAL_KEY, info.ordinal);
        info.use_email_signature = Geary.Config.get_bool_value(
            key_file, Geary.Config.GROUP, Geary.Config.USE_EMAIL_SIGNATURE_KEY, info.use_email_signature);
        info.email_signature = Geary.Config.get_escaped_string(
            key_file, Geary.Config.GROUP, Geary.Config.EMAIL_SIGNATURE_KEY, info.email_signature);

        if (info.ordinal >= Geary.AccountInformation.default_ordinal)
            Geary.AccountInformation.default_ordinal = info.ordinal + 1;

        if (info.service_provider == Geary.ServiceProvider.OTHER) {
            info.imap.load_settings();
            info.smtp.load_settings();

            if (info.smtp.smtp_use_imap_credentials) {
                info.smtp.credentials.user = info.imap.credentials.user;
                info.smtp.credentials.pass = info.imap.credentials.pass;
            }
        }

        info.drafts_folder_path = Geary.AccountInformation.build_folder_path(
            Geary.Config.get_string_list_value(key_file, Geary.Config.GROUP, Geary.Config.DRAFTS_FOLDER_KEY));
        info.sent_mail_folder_path = Geary.AccountInformation.build_folder_path(
            Geary.Config.get_string_list_value(key_file, Geary.Config.GROUP, Geary.Config.SENT_MAIL_FOLDER_KEY));
        info.spam_folder_path = Geary.AccountInformation.build_folder_path(
            Geary.Config.get_string_list_value(key_file, Geary.Config.GROUP, Geary.Config.SPAM_FOLDER_KEY));
        info.trash_folder_path = Geary.AccountInformation.build_folder_path(
            Geary.Config.get_string_list_value(key_file, Geary.Config.GROUP, Geary.Config.TRASH_FOLDER_KEY));
        info.archive_folder_path = Geary.AccountInformation.build_folder_path(
            Geary.Config.get_string_list_value(key_file, Geary.Config.GROUP, Geary.Config.ARCHIVE_FOLDER_KEY));

        info.save_drafts = Geary.Config.get_bool_value(key_file, Geary.Config.GROUP, Geary.Config.SAVE_DRAFTS_KEY, true);

        return info;
    }

    /**
     * Loads an account info from a config directory.
     *
     * Throws an error if the config file was not found, could not be
     * parsed, or doesn't have all required fields.
     */
    private static void load_from_goa(Goa.Mail mail, Geary.AccountInformation info) {


        // This is the only required value at the moment?
        string primary_email = mail.email_address;
        string real_name = mail.name;

        info.primary_mailbox = new Geary.RFC822.MailboxAddress(real_name, primary_email);
        info.nickname = "GOA Account";
        try {
            info.imap.load_credentials();
            info.smtp.load_credentials();
        } catch (GLib.Error e) {
            stdout.printf("error1\n");
        }

        if (info.ordinal >= Geary.AccountInformation.default_ordinal)
            Geary.AccountInformation.default_ordinal = info.ordinal + 1;

        try {
            info.imap.load_settings();
            info.smtp.load_settings();
        } catch (GLib.Error e) {
            stdout.printf("error2\n");
        }

    }

}
