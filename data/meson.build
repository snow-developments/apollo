config_data = configuration_data()
config_data.set('NAME', meson.project_name())
config_data.set('VERSION', meson.project_version())
config_data.set('INSTALL_PREFIX', get_option('prefix'))
config_data.set('BIN_DIR', get_option('bindir'))
config_data.set('EXEC_NAME', package)
config_data.set('GSETTINGS_KEY', package.replace('.', '/'))

appdata_in = configure_file(
  input: 'apollo.appdata.xml.in',
  output: package + '.appdata.xml.in',
  configuration: config_data,
  install: false,
)
i18n.merge_file(
  input: appdata_in,
  output: package + '.appdata.xml',
  po_dir: join_paths(meson.project_source_root(), 'po', 'extra'),
  type: 'xml',
  install: true,
  install_dir: get_option('datadir') / 'metainfo'
)

# TODO: Add a dbus media service exposing pianobar controls
# configure_file(
  # input: meson.project_name() + '.service.in',
  # output: meson.project_name() + '.service',
  # configuration: config_data,
  # install: true,
  # install_dir: join_paths(get_option('datadir'), 'dbus-1', 'services')
# )

# Configure, translate, and install .desktop file
desktop_in = configure_file(
  input: 'apollo.desktop.in',
  output: package + '.desktop.in',
  configuration: config_data,
  install: false,
)
i18n.merge_file(
  input: desktop_in,
  output: package + '.desktop',
  po_dir: join_paths(meson.project_source_root(), 'po', 'extra'),
  type: 'desktop',
  install: true,
  install_dir: join_paths(get_option('datadir'), 'applications')
)

# Configure and install GSettings schema
configure_file(
  input: meson.project_name() + '.gschema.xml.in',
  output: package + '.gschema.xml',
  configuration: config_data,
  install: true,
  install_dir: join_paths(get_option('datadir'), 'glib-2.0', 'schemas')
)

# TODO: Translate and install .appdata file
# i18n.merge_file(
#   input: join_paths('data', meson.project_name() + '.appdata.xml.in'),
#   output: meson.project_name() + '.appdata.xml',
#   po_dir: join_paths(meson.project_source_root(), 'po'),
#   install: true,
#   install_dir: join_paths(get_option('datadir'), 'metainfo')
# )

# Install icons
icon_sizes = ['16', '24', '32', '48', '64', '128']

foreach i : icon_sizes
  install_data(
    'icons' / i + '.svg',
    install_dir: get_option('datadir') / 'icons' / 'hicolor' / i + 'x' + i / 'apps',
    rename: package + '.svg'
  )
  install_data(
    'icons' / i + '.svg',
    install_dir: get_option('datadir') / 'icons' / 'hicolor' / i + 'x' + i + '@2' / 'apps',
    rename: package + '.svg'
  )
endforeach
