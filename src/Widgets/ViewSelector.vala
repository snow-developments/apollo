public class Apollo.Widgets.ViewSelector : Gtk.ToolItem {
  public signal void mode_changed (Mode new_mode);

  public enum Mode {
    ALBUM = 0,
    LIST = 1;
  }

  public Mode selected {
    get { return mode; }
    set {
      if (mode == value) return;

      mode = value;
      mode_button.selected = (int) value;
      mode_changed (value);
    }
  }

  // De-select items when the widget is made insensitive, for appearance reasons
  public new bool sensitive {
    get { return mode_button.sensitive; }
    set {
      // select third invisible mode to appear as de-selected
      mode_button.sensitive = value;
      mode_button.set_active (value ? (int) mode : -1);
      ((SimpleAction) App.main_window.lookup_action (Apollo.App.ACTION_VIEW_ALBUMS)).set_enabled (value);
      ((SimpleAction) App.main_window.lookup_action (Apollo.App.ACTION_VIEW_LIST)).set_enabled (value);
    }
  }

  private Granite.Widgets.ModeButton mode_button;
  private Mode mode;

  public ViewSelector () {
    var application_instance = ((Gtk.Application) GLib.Application.get_default ());

    var image = new Gtk.Image.from_icon_name ("view-grid-symbolic", Gtk.IconSize.MENU);
    image.tooltip_markup = Granite.markup_accel_tooltip (
        application_instance.get_accels_for_action (Apollo.App.ACTION_PREFIX + Apollo.App.ACTION_VIEW_ALBUMS),
        _("View as albums")
    );

    var list = new Gtk.Image.from_icon_name ("view-list-symbolic", Gtk.IconSize.MENU);
    list.tooltip_markup = Granite.markup_accel_tooltip (
        application_instance.get_accels_for_action (Apollo.App.ACTION_PREFIX + Apollo.App.ACTION_VIEW_LIST),
        _("View as list")
    );

    mode_button = new Granite.Widgets.ModeButton ();
    mode_button.append (image);
    mode_button.append (list);

    add (mode_button);

    mode_button.mode_changed.connect (() => {
      int new_mode = mode_button.selected;
      if (new_mode <= 1) selected = (Mode) new_mode; // Only consider first two items
      else if (mode_button.sensitive) selected = mode; // Restore last valid mode
    });
  }
}
