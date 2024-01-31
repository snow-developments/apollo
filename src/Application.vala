using Gtk;

namespace Pianobar {
  public struct Track {
    string title;
    string artist;
    string album;

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
  }

  public enum State {
    stopped,
    playing,
    paused,
    buffering
  }

  public class Player {
    public signal void state_changed ();
    public signal void track_changed ();
    public signal void position_changed (int64 position);

    public Player () {
      state = State.stopped;
      track = Track ();
      duration = 0;
    }

    public State state { get; private set; }
    public Track track { get; private set; }
    public bool has_media {
      get { return state != State.stopped; }
    }
    public int64 position { get; private set; }
    public int64 duration { get; private set; }

    public void seek (int64 position) {}
  }

  // See https://github.com/PromyLOPh/pianobar/blob/master/contrib/eventcmd-examples/eventcmd.sh
  // See /home/chances/.config/pianobar/pianobar-mediaplayer2/pianobar-mediaplayer2
  class CommandPipe {}
}

public class Apollo.App : Gtk.Application {
  public static Pianobar.Player player { get; private set; }
  public signal void play_pause_changed ();

  // private SourceListView source_list_view;
  // private ViewStack view_stack;
  // private Widgets.ViewSelector view_selector;
  private TopDisplay top_display;
  private SearchEntry search_entry;
  private bool search_field_has_focus { get; set; default = true; }

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

  protected override void activate () {
    var main_window = new ApplicationWindow (this);
    main_window.default_width = 640;
    main_window.default_height = 480;

    var header = new HeaderBar () { show_close_button = true };
    main_window.set_titlebar(header);

    top_display = new TopDisplay () {
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

    var play_button = new Gtk.Button.from_icon_name ("media-playback-start-symbolic", Gtk.IconSize.LARGE_TOOLBAR) {
      action_name = ACTION_PREFIX + ACTION_PLAY,
      tooltip_text = _("Play")
    };
    var next_button = new Gtk.Button.from_icon_name ("media-skip-forward-symbolic", Gtk.IconSize.LARGE_TOOLBAR) {
      action_name = ACTION_PREFIX + ACTION_PLAY_NEXT,
      tooltip_text = _("Skip this song")
    };

    var like_button = new Gtk.Button.from_icon_name ("emblem-favorite-symbolic", Gtk.IconSize.SMALL_TOOLBAR) {
      action_name = ACTION_PREFIX + ACTION_LIKE,
      tooltip_text = _("Like this song")
    };
    var explain_button = new Gtk.Button.from_icon_name ("dialog-question-symbolic", Gtk.IconSize.SMALL_TOOLBAR) {
      action_name = ACTION_PREFIX + ACTION_EXPLAIN,
      tooltip_text = _("Explain this song")
    };

    search_entry = new SearchEntry () {
      valign = Align.CENTER,
      placeholder_text = _("Search Stations")
    };

    header.pack_start (play_button);
    header.pack_start (next_button);
    header.pack_start (like_button);
    header.pack_start (explain_button);
    header.set_title (_("Apollo"));
    header.set_custom_title (top_display);
    header.pack_end (menu_button);
    header.pack_end (search_entry);

    main_window.show_all ();
  }

  public static int main (string[] args) {
    stdout.printf ("Sing it, Apollo!\n");
    return new App ().run (args);
  }
}
