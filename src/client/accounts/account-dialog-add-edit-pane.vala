/* Copyright 2016 Software Freedom Conservancy Inc.
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

// Add or edit an account.  Used with AccountDialog.
public class AccountDialogAddEditPane : AccountDialogPane {
    public AddEditPage add_edit_page { get; private set; default = new AddEditPage(); }
    private Gtk.ButtonBox button_box = new Gtk.ButtonBox(Gtk.Orientation.HORIZONTAL);
    private Gtk.Button ok_button = new Gtk.Button.with_mnemonic(Stock._OK);
    private Gtk.Button cancel_button = new Gtk.Button.with_mnemonic(Stock._CANCEL);
    private AccountDialogEditAlternateEmailsPane edit_alternate_emails_pane;
    private Gtk.Dialog alternates_dialog;
    
    public signal void ok(Geary.AccountInformation info);
    
    public signal void cancel();
    
    public signal void size_changed();
    

    public AccountDialogAddEditPane(Gtk.Stack stack, Gtk.Window parent_window) {
        base(stack, parent_window);
        edit_alternate_emails_pane = new AccountDialogEditAlternateEmailsPane(null);
        alternates_dialog = new Gtk.Dialog();
        alternates_dialog.set_transient_for(parent_window);
        alternates_dialog.get_content_area().pack_start(edit_alternate_emails_pane, true, true, 0);
        alternates_dialog.set_default_response(1);
        Gtk.HeaderBar hb = new Gtk.HeaderBar();
        alternates_dialog.set_titlebar(hb);
        hb.set_title("Email Addresses");
        Gtk.Button yesbutton = new Gtk.Button.with_label("OK");
        Gtk.Button nobutton = new Gtk.Button.with_label("Cancel");
        yesbutton.get_style_context().add_class("suggested-action");
        yesbutton.set_size_request(73, -1);
        nobutton.set_size_request(73, -1);
        hb.pack_start(nobutton);
        hb.pack_end(yesbutton);
        hb.show_all();
        edit_alternate_emails_pane.done.connect(on_done);
        edit_alternate_emails_pane.info_changed.connect(() => { present(); });
        
        button_box.set_layout(Gtk.ButtonBoxStyle.END);
        button_box.expand = false;
        button_box.spacing = 6;
        button_box.pack_start(cancel_button, false, false, 0);
        button_box.pack_start(ok_button, false, false, 0);
        ok_button.can_default = true;
        
        add_edit_page.info_changed.connect(on_info_changed);
        
        // Since we're not yet in a window, we have to wait before setting the default action.
        realize.connect(() => { ok_button.has_default = true; });
        
        ok_button.clicked.connect(on_ok);
        cancel_button.clicked.connect(() => { cancel(); });
        
        add_edit_page.size_changed.connect(() => { size_changed(); });
        add_edit_page.edit_alternate_emails.connect(on_edit_alternate_emails);
        
        pack_start(add_edit_page);
        pack_start(button_box, false, false);
        
        // Default mode is Welcome.
        set_mode(AddEditPage.PageMode.WELCOME);
    }
    
    public void set_mode(AddEditPage.PageMode mode) {
        ok_button.label = (mode == AddEditPage.PageMode.EDIT) ? _("_Save") : _("_Add");
        add_edit_page.set_mode(mode);
    }
    
    public AddEditPage.PageMode get_mode() {
        return add_edit_page.get_mode();
    }
    
    public void set_account_information(Geary.AccountInformation info,
        Geary.Engine.ValidationResult result = Geary.Engine.ValidationResult.OK) {
        add_edit_page.set_account_information(info, result);
    }
    
    public void set_validation_result(Geary.Engine.ValidationResult result) {
        add_edit_page.set_validation_result(result);
    }
    
    public void reset_all() {
        add_edit_page.reset_all();
    }
    
    private void on_ok() {
        ok(add_edit_page.get_account_information());
    }
    
    public override void present() {
        base.present();
        add_edit_page.update_ui();
        on_info_changed();
    }
    
    private void on_edit_alternate_emails(Gtk.ToggleButton button) {
        Geary.AccountInformation? account_info = AccountDialog.get_account_info_for_email(add_edit_page.get_account_information().id);
        if (account_info == null)
            return;

        edit_alternate_emails_pane.set_account(account_info);
        alternates_dialog.run();
}
    private void on_done() {
        add_edit_page.update_ui();
    }

    private void on_info_changed() {
//        add_edit_page.primary_mailbox.address = edit_alternate_emails_pane.get_account_information().primary_mailbox.address;
//        stdout.printf("addeditpage pref add %s\n", add_edit_page.primary_address);
        add_edit_page.update_ui();
    }
}

