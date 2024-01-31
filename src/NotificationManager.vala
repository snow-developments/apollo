public class NotificationManager : Object {
  public signal void show_alert (string title, string message);
  public signal void update_track (string message);

  private static NotificationManager? notification_manager = null;
  public static NotificationManager get_default () {
    if (notification_manager == null) notification_manager = new NotificationManager ();
    return notification_manager;
  }
}
