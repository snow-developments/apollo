// An interface such that `SourceListItem` and `SourceListExpandableItem` share a common ancestor compatible with `SourceList`.
public interface Apollo.SourceListEntry : Granite.Widgets.SourceList.Item {}

// SourceList item. It stores the number of the corresponding page in the notebook widget.
public class Apollo.SourceListItem : SourceListEntry, Granite.Widgets.SourceList.Item, Granite.Widgets.SourceListDragDest {
  public signal void station_rename_clicked (Gtk.Grid view, SourceListItem item);
  public signal void station_edit_clicked (Gtk.Grid view);
  public signal void station_remove_clicked (Gtk.Grid view);
  public signal void station_save_clicked (Gtk.Grid view);
  public signal void station_media_added (Gtk.Grid view, string[] media);

  public Gtk.Grid view { get; construct; }
  public GLib.Icon? activatable_icon { get; construct; }

  private Gtk.Menu station_menu;

  public SourceListItem (Gtk.Grid view, string name, GLib.Icon icon, GLib.Icon? activatable_icon = null) {
    Object (
      activatable_icon: activatable_icon,
      icon: icon,
      name: name,
      view: view
    );
  }

  construct {
    station_menu = new Gtk.Menu ();

    var station_rename = new Gtk.MenuItem.with_label (_("Rename"));
    station_rename.activate.connect (() => station_rename_clicked (view, this));
    var station_remove = new Gtk.MenuItem.with_label (_("Remove"));
    station_remove.activate.connect (() => station_remove_clicked (view));

    station_menu.append (station_rename);
    station_menu.append (station_remove);
    station_menu.show_all ();
  }

  private bool data_drop_possible (Gdk.DragContext context, Gtk.SelectionData data) {
    return data.get_target () == Gdk.Atom.intern_static_string ("text/uri-list");
  }

  private Gdk.DragAction data_received (Gdk.DragContext context, Gtk.SelectionData data) {
    station_media_added (view, data.get_uris ());
    return Gdk.DragAction.COPY;
  }
}

public class Apollo.StationsCategory : Granite.Widgets.SourceList.ExpandableItem, Granite.Widgets.SourceListSortable {
  private Gtk.Menu station_menu;

  public StationsCategory (string name) {
    Object (name: name);
  }

  construct {
    var station_new = new Gtk.MenuItem.with_label (_("New Station"));
    var smart_station_new = new Gtk.MenuItem.with_label (_("New Smart Station"));

    station_menu = new Gtk.Menu ();
    station_menu.append (station_new);
    station_menu.append (smart_station_new);
    station_menu.show_all ();

    station_new.activate.connect (() => App.create_new_station ());
    smart_station_new.activate.connect (() => {
      // TODO: App.show_smart_station_dialog ();
    });
  }

  public override Gtk.Menu? get_context_menu () {
    return station_menu;
  }

  // implement Sortable interface
  private bool allow_dnd_sorting () {
    return true;
  }

  private int compare (Granite.Widgets.SourceList.Item a, Granite.Widgets.SourceList.Item b) {
    if (a == null || b == null) return 0;

    // TODO: Playse QuickMix first

    // Sort stations alphabetically
    var item_a = a as SourceListItem;
    return strcmp (item_a.name.collate_key (), (b as SourceListItem).name.collate_key ());
  }
}

public class Apollo.SourceListRoot : Granite.Widgets.SourceList.ExpandableItem, Granite.Widgets.SourceListSortable {
  public SourceListRoot () {
    base ("SourceListRoot");
  }

  private bool allow_dnd_sorting () {
    return true;
  }

  private int compare (Granite.Widgets.SourceList.Item a, Granite.Widgets.SourceList.Item b) {
    return 0;
  }
}

public class Apollo.Widgets.SourceListView : Granite.Widgets.SourceList {
  Granite.Widgets.SourceList.ExpandableItem stations_category;
  Granite.Widgets.SourceList.ExpandableItem devices_category;

  public SourceListView () {
    base (new SourceListRoot ());

    set_size_request (Apollo.settings.get_int("minimum-sidebar-width"), 0);

    // Adds the different sidebar categories.
    devices_category = new Granite.Widgets.SourceList.ExpandableItem (_("Devices"));
    stations_category = new StationsCategory (_("Stations"));
    this.root.add (stations_category);
    this.root.expand_all (false, false);

    Gtk.TargetEntry uri_list_entry = { "text/uri-list", Gtk.TargetFlags.SAME_APP, 0 };
    enable_drag_dest ({ uri_list_entry }, Gdk.DragAction.COPY);
  }
}
