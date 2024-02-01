/*-
 * Copyright (c) 2012-2018 elementary LLC. (https://elementary.io)
 * Copyright (c) 2024 Snow Developments LLC. (https://snow.llc)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * The Music authors hereby grant permission for non-GPL compatible
 * GStreamer plugins to be used and distributed together with GStreamer
 * and Music. This permission is above and beyond the permissions granted
 * by the GPL license by which Music is covered. If you modify this code
 * you may extend this exception to your version of the code, but you are not
 * obligated to do so. If you do not wish to do so, delete this exception
 * statement from your version.
 *
 * Authored by: Scott Ringwelski <sgringwe@mtu.edu>
 *              Chance Snow <git@chancesnow.me>
 */

public class Apollo.Widgets.TopDisplay : Gtk.Stack {
  // public MusicListView list_view { get; set; }

  public signal void scale_value_changed (Gtk.ScrollType scroll, double val);

  private TitleLabel track_label;
  private Granite.SeekBar seek_bar;
  private uint change_timeout_id = 0;

  construct {
    seek_bar = new Granite.SeekBar (0.0);

    var track_eventbox = new Gtk.EventBox ();
    track_eventbox.add (track_label = new TitleLabel (_("Ready")));

    // TODO: Show a context menu with actions like "Ban song for one month", "Block this song", "Create station from song/artist", and "Bookmark song/artist"
    // track_eventbox.button_press_event.connect ((e) => {
    //   if (e.button == Gdk.BUTTON_SECONDARY) {
    //     var current = new Gee.TreeSet<Track> ();
    //     if (App.player.track != null) current.add (App.player.track);
    //     list_view.track_action_menu.popup_track_menu (current);
    //     return true;
    //   }
    //
    //   return false;
    // });

    var time_grid = new Gtk.Grid () { column_spacing = 12 };
    time_grid.attach (track_eventbox, 1, 0, 1, 1);
    time_grid.attach (seek_bar, 0, 1, 3, 1);

    var title = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
    title.set_center_widget (new TitleLabel (_("Apollo")));

    transition_type = Gtk.StackTransitionType.CROSSFADE;
    add_named (time_grid, "time");
    add_named (title, "empty");
    show_all ();

    visible_child_name = "empty";

    seek_bar.scale.change_value.connect (change_value);
    App.player.position_changed.connect (player_position_update);
    App.player.track_changed.connect (update_current_media);

    NotificationManager.get_default ().update_track.connect ((message) => {
      track_label.set_markup (message);
    });
  }

  private class TitleLabel : Gtk.Label {
    public TitleLabel (string label) {
      Object (label: label);
      hexpand = true;
      justify = Gtk.Justification.CENTER;
      ellipsize = Pango.EllipsizeMode.END;
      get_style_context ().add_class (Gtk.STYLE_CLASS_TITLE);
    }
  }

  public override void get_preferred_width (out int minimum_width, out int natural_width) {
    base.get_preferred_width (out minimum_width, out natural_width);
    minimum_width = 200;
    if (natural_width < 600) {
      natural_width = 600;
    }
  }

  public virtual bool change_value (Gtk.ScrollType scroll, double val) {
    scale_value_changed (scroll, val);

    if (change_timeout_id > 0) Source.remove (change_timeout_id);
    change_timeout_id = Timeout.add (300, () => {
      if (seek_bar.is_grabbing)
        App.player.seek ((int64) TimeUtils.seconds_to_nanoseconds ((uint) (val * seek_bar.playback_duration)));

      change_timeout_id = 0;
      return false;
    });

    return false;
  }

  public virtual void player_position_update (int64 position) {
    if (!App.player.has_media) return;
    seek_bar.playback_progress = ((double) TimeUtils.nanoseconds_to_seconds (position)) / seek_bar.playback_duration;
  }

  private void update_current_media () {
    if (App.player.has_media) {
      NotificationManager.get_default ().update_track (App.player.track.get_title_markup ());
      seek_bar.playback_duration = ((double) App.player.duration) / 1000.0;
    }
    visible_child_name = App.player.has_media ? "time" : "empty";
  }
}
