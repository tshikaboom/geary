/* Copyright 2016 Software Freedom Conservancy Inc.
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

public class AccountDialogEditAlternateEmailsPane : Gtk.Box {
    private class ListItem : Gtk.Box {
        public enum button_mode {
            MAILBOX,
            ADD
        }
        public button_mode mode;
        public bool has_mailbox = false;
        public Geary.RFC822.MailboxAddress mailbox;
        private Gtk.Label label;
        private Gtk.Image? checkbox = null;
        private Gtk.Button? del = null;
        private Gtk.Builder builder;
        private Gtk.Popover modify_popover;

        construct {
            modify_popover = new Gtk.Popover(null);
            builder = GearyApplication.instance.create_builder("edit_alternate_emails.glade");
            modify_popover.add((Gtk.Grid) builder.get_object("popover_container"));
        }

        public ListItem(Geary.RFC822.MailboxAddress mailbox, bool checked, bool primary) {
            Object(orientation: Gtk.Orientation.HORIZONTAL, spacing: 4);
            this.mode = ListItem.button_mode.MAILBOX;
            // set_margin_top(6);
            //set_margin_end(6);
            set_margin_start(6);
            set_margin_end(6);

            label = new Gtk.Label(null);
            this.mailbox = mailbox;
            has_mailbox = true;
            pack_start(label, false, false, 0);
            this.label.label = "<b>%s</b>".printf(Geary.HTML.escape_markup(mailbox.get_full_address()));
            label.use_markup = true;
            label.set_ellipsize(Pango.EllipsizeMode.END);
            GtkUtil.set_label_xalign(label, 0.0f);
            if (checked) {

            checkbox = new Gtk.Image.from_icon_name("object-select-symbolic", Gtk.IconSize.MENU);
            checkbox.set_halign(Gtk.Align.CENTER);
            checkbox.set_valign (Gtk.Align.CENTER);
            pack_start (checkbox, false, false, 0);

                checkbox.show();
            }
            else {
                checkbox.destroy();
            }

            del = new Gtk.Button.from_icon_name("list-remove-symbolic", Gtk.IconSize.MENU);
            del.set_relief(Gtk.ReliefStyle.NONE);
            pack_end(del, false, false, 0);

        }

        public ListItem.add_button() {
            Object(orientation: Gtk.Orientation.HORIZONTAL, spacing: 4);
            this.mode = ListItem.button_mode.ADD;
            Gtk.Button addbutton = new Gtk.Button.from_icon_name("list-add-symbolic", Gtk.IconSize.MENU);
            addbutton.set_relief(Gtk.ReliefStyle.NONE);
            pack_start(addbutton, true, false, 0);
        }

        public void modify() {
            modify_popover.set_relative_to(this);
            modify_popover.show_all();
        }
    }

    public bool changed { get; private set; default = false; }

    private Gtk.ListBox address_listbox;
//    private Gtk.ToolButton delete_button;
    private ListItem? selected_item = null;
    
    private Geary.AccountInformation? account_info = null;
    private Geary.RFC822.MailboxAddress? primary_mailbox = null;
    private Gee.HashSet<Geary.RFC822.MailboxAddress> mailboxes = new Gee.HashSet<Geary.RFC822.MailboxAddress>();
    
    public signal void done();
    public signal void info_changed();

    public AccountDialogEditAlternateEmailsPane(Gtk.Widget? widget) {
        Object(orientation:Gtk.Orientation.VERTICAL, spacing:4);

        stdout.printf("Yeah\n");
        set_size_request(400, 200);

        Gtk.Builder builder = GearyApplication.instance.create_builder("edit_alternate_emails.glade");

        // Primary container
        pack_start((Gtk.Widget) builder.get_object("container"));

        address_listbox = (Gtk.ListBox) builder.get_object("address_listbox");

        address_listbox.border_width = 2;
        address_listbox.set_selection_mode(Gtk.SelectionMode.NONE);
        address_listbox.row_selected.connect(on_row_selected);
        address_listbox.row_activated.connect(on_row_activated);
        address_listbox.set_activate_on_single_click(true);
        show();
    }
/*
    private bool validate_address_text(string email_address, out Geary.RFC822.MailboxAddress? parsed) {
        parsed = null;

        Geary.RFC822.MailboxAddresses mailboxes = new Geary.RFC822.MailboxAddresses.from_rfc822_string(
            email_address);
        if (mailboxes.size != 1)
            return false;

        Geary.RFC822.MailboxAddress mailbox = mailboxes.get(0);

        if (!mailbox.is_valid())
            return false;

//        if (Geary.String.stri_equal(mailbox.address, primary_mailbox.address))
//            return false;
        
        if (Geary.String.is_empty(mailbox.address))
            return false;
        
        parsed = mailbox;
        
        return true;
    }

    private bool transform_email_to_sensitive(Binding binding, Value source, ref Value target) {
        Geary.RFC822.MailboxAddress? parsed;
        target = validate_address_text(email_entry.text, out parsed) && !mailboxes.contains(parsed);

        return true;
    }
    */

    public void set_account(Geary.AccountInformation account_info) {
        this.account_info = account_info;
        this.primary_mailbox = account_info.primary_mailbox;
        this.mailboxes.clear();
        this.changed = false;

        // clear listbox
        foreach (Gtk.Widget widget in this.address_listbox.get_children()) {
            address_listbox.remove(widget);
            widget.destroy();
        }
        
        // Add all email addresses; add_email_address() silently drops the primary address
        foreach (Geary.RFC822.MailboxAddress mailbox in account_info.get_all_mailboxes())
            add_mailbox(mailbox, false);

        address_listbox.add(new ListItem.add_button());
        address_listbox.show_all();
    }

    public void present() {
        show_all();
    }

    private void add_mailbox(Geary.RFC822.MailboxAddress mailbox, bool is_change) {
//        if (mailboxes.contains(mailbox) || primary_mailbox.equal_to(mailbox))
//            return;
        bool primary = false, favorite = false;
        ListItem item;
        mailboxes.add(mailbox);
        if (mailbox.address == account_info.primary_mailbox.address)
            favorite = true;
        if (mailbox.address == account_info.primary_mailbox.address)
            primary = true;
        item = new ListItem(mailbox, favorite, primary);

        address_listbox.add(item);

        if (is_change)
            changed = true;
    }
    /*
    private void remove_mailbox(Geary.RFC822.MailboxAddress address) {
        if (!mailboxes.remove(address))
            return;
        
        foreach (Gtk.Widget widget in address_listbox.get_children()) {
            Gtk.ListBoxRow row = (Gtk.ListBoxRow) widget;
            ListItem item = (ListItem) row.get_child();
            
            if (item.mailbox.equal_to(address)) {
                address_listbox.remove(widget);
                
                changed = true;
                
                break;
            }
        }
    }
    */
    private void on_row_selected(Gtk.ListBoxRow? row) {
        selected_item = (row != null) ? (ListItem) row.get_child() : null;
//        delete_button.sensitive = (selected_item != null);
    }

    private void on_row_activated(Gtk.ListBoxRow? row) {
    if (row == null)
        return;

    ListItem item = (ListItem) row.get_child();
    if (item == null)
        return;


    if (item.mode == ListItem.button_mode.MAILBOX) {
        account_info.primary_mailbox = item.mailbox;
        stdout.printf("activated %s\n", item.mailbox.address);
//        set_account(this.account_info);
        info_changed();
    }
    item.modify();
}
    public Geary.AccountInformation get_account_information() {
        return account_info;
    }

}

