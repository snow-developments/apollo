using Gtk;

namespace Pianobar {
  public struct Station {
    string id;
    string name;
    Gee.List<Track> history;
  }

  public class Track {
    public virtual string title { get; set; }
    public virtual string artist { get; set; }
    public virtual string album { get; set; }
    public virtual bool liked { get; set; }
    public virtual bool liked_artist { get; set; }

    public static inline bool is_valid_string_field (string? text) {
      return !String.is_empty (text, true);
    }

    public string get_title_markup () {
      // If some info is not available, just skip it.
      bool is_valid_artist = is_valid_string_field (artist);
      bool is_valid_album = is_valid_string_field (album);
      if (!is_valid_artist && is_valid_album) {
        /// Keep $NAME and $ALBUM, they will be replaced by their values
        return _("$NAME on $ALBUM").replace ("$ALBUM", "<b>" + Markup.escape_text (album) + "</b>").replace ("$NAME", "<b>" + Markup.escape_text (title) + "</b>");
      } else if (is_valid_artist && !is_valid_album) {
        /// Keep $NAME and $ARTIST, they will be replaced by their values
        return _("$NAME by $ARTIST").replace ("$ARTIST", "<b>" + Markup.escape_text (artist) + "</b>").replace ("$NAME", "<b>" + Markup.escape_text (title) + "</b>");
      } else if (!is_valid_artist && !is_valid_album) {
        /// Keep $NAME and $ARTIST, they will be replaced by their values
        return "<b>" + Markup.escape_text (title) + "</b>";
      } else {
        /// Keep $NAME, $ARTIST and $ALBUM, they will be replaced by their values
        return _("$NAME by $ARTIST on $ALBUM").replace ("$ARTIST", "<b>" + Markup.escape_text (artist) + "</b>").replace ("$NAME", "<b>" + Markup.escape_text (title) + "</b>").replace ("$ALBUM", "<b>" + Markup.escape_text (album) + "</b>");
      }
    }

    public Track copy () {
      var result = new Track ();

      result.title = title;
      result.artist = artist;
      result.album = album;
      result.liked = liked;
      result.liked_artist = liked_artist;

      return result;
    }
  }

  public enum State {
    stopped,
    playing,
    paused,
    buffering
  }

  public class Player {
    public bool authenticated { get; private set; default = false; }
    public State state { get; private set; }
    public Track track { get; private set; }
    public bool has_media {
      get { return state != State.stopped; }
    }
    public int64 position { get; private set; }
    public int64 duration { get; private set; }
    public Gee.TreeSet<Station?> stations { get; private set; }

    public signal void state_changed ();
    public signal void track_changed ();
    public signal void position_changed (int64 position);

    public Player () {
      state = State.stopped;
      track = null;
      position = 0;
      duration = 0;
      stations = new Gee.TreeSet<Station?> ((a, b) => {
        return strcmp (a.name.collate_key (), b.name.collate_key ());
      });
    }

    public void seek (int64 position) {}
  }

  // See https://github.com/PromyLOPh/pianobar/blob/master/contrib/eventcmd-examples/eventcmd.sh
  // See /home/chances/.config/pianobar/pianobar-mediaplayer2/pianobar-mediaplayer2
  class CommandPipe {}
}

namespace Apollo {
  public GLib.Settings saved_state;
  public GLib.Settings settings;
  public GLib.Settings album_view_settings;
  public GLib.Settings list_view_settings;

  public class App : Gtk.Application {
    public static ApplicationWindow main_window { get; private set; }
    public static Pianobar.Player player { get; private set; }
    public signal void play_pause_changed ();

    private Stack view_stack;
    private Widgets.SourceListView source_list_view;
    private Widgets.StatusBar statusbar;
    // private Widgets.ViewSelector view_selector;
    private Widgets.TopDisplay top_display;
    private SearchEntry search_entry;
    private bool search_field_has_focus { get; set; default = true; }
    private Granite.Widgets.Welcome welcome;

    public const string ACTION_PREFIX = "win.";
    public const string ACTION_PLAY = "action_play";
    public const string ACTION_PLAY_NEXT = "action_play_next";
    public const string ACTION_LIKE = "action_like";
    public const string ACTION_EXPLAIN = "action_explain";
    public const string ACTION_QUIT = "action_quit";
    public const string ACTION_SEARCH = "action_search";
    public const string ACTION_VIEW_ALBUMS = "action_view_albums";
    public const string ACTION_VIEW_LIST = "action_view_list";

    public App () {
      Object (
        application_id: "llc.snow.apollo",
        flags: ApplicationFlags.FLAGS_NONE
      );

      player = new Pianobar.Player ();
    }

    static construct {
      // Init settings
      saved_state = new GLib.Settings (Constants.EXEC_NAME + ".saved-state");
      settings = new GLib.Settings (Constants.EXEC_NAME + ".preferences");
      album_view_settings = new GLib.Settings (Constants.EXEC_NAME + ".album-view");
      list_view_settings = new GLib.Settings (Constants.EXEC_NAME + ".list-view");
    }

    protected override void activate () {
      main_window = new ApplicationWindow (this);
      main_window.default_width = 640;
      main_window.default_height = 480;

      var header = new HeaderBar () { show_close_button = true };
      main_window.set_titlebar(header);

      var view_selector = new Widgets.ViewSelector () {
        margin_start = 12,
        margin_end = 6,
        valign = Align.CENTER
      };
      // TODO: view_selector.selected = (Widgets.ViewSelector.Mode) App.saved_state.get_int ("view-mode");

      var play_button = new Button.from_icon_name ("media-playback-start-symbolic", IconSize.LARGE_TOOLBAR) {
        action_name = ACTION_PREFIX + ACTION_PLAY,
        tooltip_text = _("Play"),
        margin_start = 12
      };
      action_state_changed.connect ((name, new_state) => {
        if (name == ACTION_PLAY) {
          if (new_state.get_boolean () == false) {
            play_button.image = new Gtk.Image.from_icon_name ("media-playback-start-symbolic", Gtk.IconSize.LARGE_TOOLBAR);
            play_button.tooltip_text = _("Play");
          } else {
            play_button.image = new Gtk.Image.from_icon_name ("media-playback-pause-symbolic", Gtk.IconSize.LARGE_TOOLBAR);
            play_button.tooltip_text = _("Pause");
          }
        }
      });
      var next_button = new Button.from_icon_name ("media-skip-forward-symbolic", IconSize.LARGE_TOOLBAR) {
        action_name = ACTION_PREFIX + ACTION_PLAY_NEXT,
        tooltip_text = _("Skip this song")
      };

      top_display = new Widgets.TopDisplay () {
        visible_child_name = "time",
        margin_start = 30,
        margin_end = 30
      };
      // top_display.visible = player.state != Pianobar.State.stopped;
      // sensitive = player.state != Pianobar.State.buffering;

      var preferences_menuitem = new Gtk.MenuItem.with_label (_("Preferences"));
      // TODO: preferences_menuitem.activate.connect (edit_preferences_click);

      var menu = new Gtk.Menu ();
      menu.append (preferences_menuitem);
      menu.show_all ();

      var menu_button = new MenuButton ();
      menu_button.image = new Image.from_icon_name ("open-menu", IconSize.LARGE_TOOLBAR);
      menu_button.popup = menu;
      menu_button.valign = Align.CENTER;

      search_entry = new SearchEntry () {
        valign = Align.CENTER,
        placeholder_text = _("Search Stations")
      };

      header.pack_start (play_button);
      header.pack_start (next_button);
      header.pack_start (view_selector);
      header.set_title (_("Apollo"));
      header.set_custom_title (top_display);
      header.pack_end (menu_button);
      header.pack_end (search_entry);

      view_stack = new Stack () {
        transition_type = Gtk.StackTransitionType.CROSSFADE
      };

      var login = new Grid () {
        halign = Align.CENTER,
        valign = Align.CENTER,
        row_spacing = 8
      };

      Entry username = new Entry () {
        activates_default = true,
        placeholder_text = _("user@example.com")
      };
      Entry password = new Entry () {
        activates_default = true,
        primary_icon_name = "dialog-password-symbolic",
        primary_icon_tooltip_text = _("Password"),
        visibility = false,
        input_purpose = InputPurpose.PASSWORD,
        caps_lock_warning = true
      };

      var login_button = new Button.with_label (_("Login")) {
        sensitive = false
      };
      username.changed.connect (() => {
        login_button.sensitive = (String.is_empty(username.text, true)  == false) && (String.is_empty(password.text, true) == false);
      });
      password.changed.connect (() => {
        login_button.sensitive = (String.is_empty(username.text, true)  == false) && (String.is_empty(password.text, true) == false);
      });
      login_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
      login_button.clicked.connect (() => {
        if (String.is_empty(username.text, true) || String.is_empty(password.text, true)) return;
        // TODO: Login to Pandora
        view_stack.visible_child_name = "player";
      });

      var login_label = new Label (_("Login to Pandora"));
      login_label.get_style_context ().add_class (Granite.STYLE_CLASS_H1_LABEL);
      login.attach (login_label, 0, 0, 3, 1);
      login.attach (username, 0, 1, 3, 1);
      login.attach (password, 0, 2, 3, 1);
      login.attach (login_button, 2, 3, 1, 1);

      welcome = new Granite.Widgets.Welcome ("", "");
      welcome.activated.connect ((_) => {
        if (player.authenticated && player.stations.size == 0) {
          // TODO: Show the new station dialog
        } else {
          view_stack.visible_child_name = "login";
          username.grab_focus ();
        }
      });

      var sidebar_grid = new Gtk.Grid () {
        orientation = Gtk.Orientation.VERTICAL
      };
      sidebar_grid.get_style_context ().add_class (Gtk.STYLE_CLASS_SIDEBAR);
      sidebar_grid.add (source_list_view = new Widgets.SourceListView ());
      sidebar_grid.add (statusbar = new Widgets.StatusBar ());

      var track_view = new Grid () {
        halign = Align.CENTER,
        valign = Align.CENTER
      };
      var like_button = new Gtk.Button.from_icon_name ("emblem-favorite-symbolic", Gtk.IconSize.SMALL_TOOLBAR) {
        action_name = ACTION_PREFIX + ACTION_LIKE,
        tooltip_text = _("Like this song")
      };
      var explain_button = new Gtk.Button.from_icon_name ("dialog-question-symbolic", Gtk.IconSize.SMALL_TOOLBAR) {
        action_name = ACTION_PREFIX + ACTION_EXPLAIN,
        tooltip_text = _("Explain this song")
      };
      track_view.attach (like_button, 0, 0, 1, 1);
      track_view.attach (explain_button, 3, 0, 1, 1);
      track_view.attach (new Label (_("Current Track")) {
        hexpand = true,
        justify = Justification.CENTER,
        ellipsize = Pango.EllipsizeMode.END
      }, 1, 0, 2, 1);
      track_view.attach (new Image (), 1, 1, 2, 2);

      var player_view = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);
      player_view.pack1 (sidebar_grid, false, false);
      player_view.pack2 (track_view, true, false);
      player_view.show_all ();

      view_stack.add_named (welcome, "welcome");
      view_stack.add_named (login, "login");
      view_stack.add_named (player_view, "player");

      update_welcome ();

      main_window.add (view_stack);
      main_window.show_all ();
    }

    public static int main (string[] args) {
      stdout.printf ("Sing it, Apollo!\n");
      return new App ().run (args);
    }

    public static void create_new_station () {
      new Dialogs.StationEditor ().run ();
    }

    private void update_welcome () {
      welcome.remove_item (0);
      if (player.authenticated == false) {
        welcome.title = _("Login to Pandora");
        welcome.subtitle = _("Login to start playing music.");
        welcome.append ("contact-new", _("Login to Pandora"), _("Login with your pandora.com credentials."));
        view_stack.visible_child_name = "welcome";
      } else if (player.stations.size == 0) {
        welcome.title = _("No Stations Created");
        welcome.subtitle = _("Create a new station to start playing music.");
        welcome.append ("list-add", _("Create a Station"), _("Granite's source code is hosted on GitHub."));
        view_stack.visible_child_name = "welcome";
      } else if (player.authenticated && player.stations.size > 0) {
        view_stack.visible_child_name = "player";
      }
    }
  }
}
