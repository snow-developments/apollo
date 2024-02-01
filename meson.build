project(
  'apollo', ['c', 'vala'],
  'vala', 'c',
  version: '0.1.0',
  meson_version: '>= 0.56.0'
)
package = 'llc.snow.@0@'.format(meson.project_name())
i18n = import('i18n')

# Minimum Vala version
vala_version_required = '0.40.0'
vala = meson.get_compiler('vala')
cc = meson.get_compiler('c')

if not vala.version().version_compare('>= @0@'.format(vala_version_required))
  error('Valac >= @0@ required!'.format(vala_version_required))
endif

# add_project_arguments(
#   ['--vapidir', join_paths(meson.current_source_dir(), 'vapi')],
#   language: 'vala'
# )

# Set our translation domain
add_global_arguments('-DGETTEXT_PACKAGE="@0@"'.format (package), language:'c')

# Dependencies
min_glib_version = '2.56.0'

glib_dep = dependency('glib-2.0', version: '>=' + min_glib_version)
gobject_dep = dependency('gobject-2.0', version: '>=' + min_glib_version)
deps = [
  glib_dep,
  gobject_dep,
  dependency('gee-0.8'),
  dependency('gtk+-3.0', version: '>=3.20.0'),
  dependency('granite', version: '>=5.0.0'),
  dependency('sqlite3')
]

# Configuration
config_data = configuration_data()
config_data.set('NAME', meson.project_name())
config_data.set('EXEC_NAME', package)
config_data.set('VERSION', meson.project_version())
config_data.set('GETTEXT_PACKAGE', package)
config_data.set('INSTALL_PREFIX', get_option('prefix'))
config_data.set('BIN_DIR', join_paths(get_option('prefix'), get_option('bindir')))
config_data.set('DATA_DIR', join_paths(get_option('prefix'), get_option('datadir')))
config_data.set('LOCALE_DIR', join_paths(get_option('prefix'), get_option('localedir')))
config_data.set('TEST_DATA_DIR', join_paths(meson.project_source_root(), 'data', 'tests'))
config_data.set('GSETTINGS_KEY', package.replace('.', '/'))

config_header = configure_file(
  input: 'src/Constants.vala.in',
  output: 'Constants.vala',
  configuration : config_data
)

# Configure subdirectories
subdir('data')
subdir('po')

exe = executable(
  package,
  config_header,
  'src/NotificationManager.vala',
  'src/Application.vala',
  'src/Utils/Search.vala',
  'src/Utils/String.vala',
  'src/Utils/TimeUtils.vala',
  'src/Widgets/TopDisplay.vala',
  dependencies: deps,
  install: true
)

test('basic', exe)
