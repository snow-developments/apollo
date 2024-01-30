namespace Pianobar {
  // See https://github.com/PromyLOPh/pianobar/blob/master/contrib/eventcmd-examples/eventcmd.sh
  // See /home/chances/.config/pianobar/pianobar-mediaplayer2/pianobar-mediaplayer2
  class CommandPipe {}
}

public class Apollo : Gtk.Application {
  public Apollo () {
    Object (
      application_id: "llc.snow.apollo",
      flags: ApplicationFlags.FLAGS_NONE
    );
  }

  protected override void activate () {
    var main_window = new Gtk.ApplicationWindow (this);
    main_window.default_width = 640;
    main_window.default_height = 480;
    main_window.title = _("Apollo");
    main_window.show_all ();
  }

  public static int main (string[] args) {
    stdout.printf ("Hello apollo!\n");
    return new Apollo ().run (args);
  }
}
