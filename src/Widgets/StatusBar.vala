public class Apollo.Widgets.StatusBar : Gtk.ActionBar {
  private Gtk.MenuButton station_menu;

  public bool station_menu_sensitive {
    set { station_menu.sensitive = value; }
  }

  construct {
    var add_station = new Gtk.MenuItem.with_label (_("Add Station"));
    add_station.activate.connect (() => App.create_new_station ());
    var add_smart_station = new Gtk.MenuItem.with_label (_("Add Smart Station"));
    add_smart_station.activate.connect (() => {
      // TODO: Create a station editor dialog
      // var smart_station_editor = new SmartStationEditor (null, App.library_manager);
      // smart_station_editor.show ();
    });

    var menu = new Gtk.Menu ();
    menu.append (add_station);
    menu.append (add_smart_station);
    menu.show_all ();

    station_menu = new Gtk.MenuButton () {
      always_show_image = true,
      direction = Gtk.ArrowType.UP,
      image = new Gtk.Image.from_icon_name ("list-add-symbolic", Gtk.IconSize.SMALL_TOOLBAR),
      tooltip_text = _("Add Station"),
      popup = menu
    };

    get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
    pack_start (station_menu);
  }
}
