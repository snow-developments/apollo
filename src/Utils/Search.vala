using Pianobar;
/*-
 * Copyright (c) 2012-2018 elementary LLC. (https://elementary.io)
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
 * Authored by: Victor Eduardo <victoreduardm@gmail.com>
 */

namespace Search {

  /*
   * Linear exact-string-matching search method.
   *
   * To mean "ALL", pass an empty string (i.e.: "") for string parameters; and
   * -1 for integer parameters.
   *
   * Please note that this method compares against the values returned by
   * Media.get_display_*(), and not the real fields. This means that a value
   * like 'Unknown' will have a matching media even if the actual field is empty.
   *
   *
   * Used by the column browser. Fields compared must match those *displayed* by the browser.
   *
   * /!\ Modify carefully.
   */
  public void search_in_media_list (Gee.Collection<Track?> to_search,
                                    out Gee.Collection<Track?> results,
                                    string artist = "",
                                    string album = "",
                                    Cancellable? cancellable = null) {
    results = new Gee.TreeSet<Track?> ();

    foreach (var media in to_search) {
      if (cancellable != null && cancellable.is_cancelled ()) break;
      if (match_fields_to_media (media, artist, album)) results.add (media);
    }
  }

  /*
   * Used by the column browser. Fields compared must match those *displayed* by the browser.
   *
   * /!\ Modify carefully.
   */
  public inline bool match_fields_to_media (Track media,
                                            string artist = "",
                                            string album = "") {
    return (String.is_empty (artist, false) || media.artist == artist)
        && (String.is_empty (album, false) || media.album == album);
  }

  private inline string get_valid_search_string (string s) {
    return String.canonicalize_for_search (s);
  }

  /*
   * Parses a rating from stars. e.g. "***" => 3
   * Returns -1 if rating_string doesn't represent a valid rating.
   *
   * This method ''never'' returns zero. It simply doesn't make sense to
   * return a rating of zero for any given empty string.
   *
   * Samples of valid strings:
   *   "*"
   *   "****"
   * Samples of invalid strings:
   *   ""
   *   "  "
   *   "**a"
   */
  private inline uint? get_rating_from_string (string rating_string)
    ensures (result != 0) {
    int i = 0;
    unichar c;
    uint rating;

    for (rating = 0; rating_string.get_next_char (ref i, out c); rating++) {
      if (c != '*') return null;
    }

    if (rating == 0) return null;

    return rating;
  }

  public inline bool match_string_to_media (Track m, string search) {
    return search in get_valid_search_string (m.title)
        || search in get_valid_search_string (m.album)
        || search in get_valid_search_string (m.artist);
  }
}
