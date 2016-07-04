/* Copyright 2016 Software Freedom Conservancy Inc.
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */

namespace XdgDir {

private const string SETTINGS_FILENAME = Geary.AccountInformation.SETTINGS_FILENAME;

/* Utility function to copy geary.ini to the XDG configuration directory.
 * It iterates through all the account directories in $XDG_DATA_DIR and copies over
 * only geary.ini. Note that it leaves the original file untouched. */
public void migrate_configuration(File user_data_dir, File user_config_dir) {
    File new_config_dir;
    File old_config_file;
    File new_config_file;
    
    /* Only copy the configuration if $XDG_CONFIG_DIR/geary does not exist and
     * $XDG_DATA_DIR/geary does exist. */
    if ((!user_config_dir.query_exists()) && (user_data_dir.query_exists())) {
        try {
            user_config_dir.make_directory_with_parents();
        } catch (Error err) {
            error("Error creating configuration directory: %s", err.message);
        }
        
        // Create the same directory tree in $XDG_CONFIG_DIR as in $XDG_DATA_DIR
        FileEnumerator enumerator;
        try {
            enumerator = user_data_dir.enumerate_children ("standard::*",
                FileQueryInfoFlags.NOFOLLOW_SYMLINKS, null);
        } catch (Error err) {
            error("Error querying configuration directory: %s", err.message);
        }
        FileInfo? info;
        try {
            while ((info = enumerator.next_file(null)) != null) {
                if (info.get_file_type() == FileType.DIRECTORY) {
                    new_config_dir = File.new_for_path(user_config_dir.get_path() + "/" + info.get_name());
                    if (!new_config_dir.query_exists()) {
                        new_config_dir.make_directory_with_parents();
                    }
                    
                    new_config_file = File.new_for_path(new_config_dir.get_path() + "/" + SETTINGS_FILENAME);
                    if (!new_config_file.query_exists()) {
                        old_config_file = File.new_for_path(user_data_dir.get_path() + "/" + info.get_name() + "/" + SETTINGS_FILENAME);
                        old_config_file.copy(new_config_file, FileCopyFlags.NONE);
                    }
                }
            }
        } catch (Error err) {
            error("Error copying configuration over: %s", err.message);
        }
    }
    else return;
}
}

