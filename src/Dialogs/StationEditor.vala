using Pianobar;

public class Apollo.Dialogs.StationEditor : Granite.Dialog {
  public Station? station { get; private set; }

  private bool is_new = false;
  private Gtk.Entry name_entry;
  private Gtk.Button save_button;

  public StationEditor (Station? station = null) {
    Object (
      transient_for: App.main_window,
      destroy_with_parent: true,
      width_request: 400,
      height_request: 300,
      resizable: true
    );

    this.station = station;
  }

  construct {
    is_new = station == null;

    name_entry = new Gtk.Entry () {
      hexpand = true,
      placeholder_text = "Madonna"
    };
    name_entry.changed.connect (name_changed);

    var form = new Gtk.Grid () {
      expand = true,
      margin_start = 12,
      margin_end = 12,
      column_spacing = 12
    };

    form.attach (new Granite.HeaderLabel (_("Song or Artist:")), 0, 0, 1, 1);
    form.attach (name_entry, 0, 1, 1, 1);
    form.show_all ();

    get_content_area ().add (form);

    add_button (_("Close"), Gtk.ResponseType.CLOSE);

    save_button = (Gtk.Button) add_button (is_new ? _("Create") : _("Save"), Gtk.ResponseType.APPLY);
    save_button.sensitive = false;
    save_button.has_default = true;
    save_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);

    response.connect ((response_id) => {
      if (response_id == Gtk.ResponseType.APPLY) save_and_exit ();
      destroy ();
    });
  }

  public void save_and_exit () {
    if (is_new) station = Station ();
    station.name = name_entry.text.strip ();
  }

  private void name_changed () {
    if (String.is_white_space (name_entry.text)) {
      (save_button as Gtk.Button).sensitive = false;
      return;
    }

    (save_button as Gtk.Button).sensitive = true;
  }
}
